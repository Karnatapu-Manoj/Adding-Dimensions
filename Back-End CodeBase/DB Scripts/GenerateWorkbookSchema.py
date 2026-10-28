"""Generate PostgreSQL table scripts from the client's XLSX using only Python's standard library.

Run from any folder:
python "DB Scripts/GenerateWorkbookSchema.py" "../Reference Documents/design thinking Db and partition.xlsx"

The workbook is the source for columns, types, nullability, defaults, identity keys,
unique keys, and foreign keys. Foreign keys are added after all tables to support
the workbook's circular app_user audit relationships.
"""
import argparse
import json
import re
import xml.etree.ElementTree as ET
import zipfile
from collections import OrderedDict
from pathlib import Path

NAMESPACE = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}


def read_dictionary(workbook):
    with zipfile.ZipFile(workbook) as archive:
        shared = []
        if "xl/sharedStrings.xml" in archive.namelist():
            shared = ["".join(node.text or "" for node in item.findall(".//s:t", NAMESPACE))
                      for item in ET.fromstring(archive.read("xl/sharedStrings.xml")).findall("s:si", NAMESPACE)]
        relationships = {item.attrib["Id"]: item.attrib["Target"]
                         for item in ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))}
        sheets = ET.fromstring(archive.read("xl/workbook.xml")).findall("s:sheets/s:sheet", NAMESPACE)
        sheet = next(item for item in sheets if item.attrib["name"].strip() == "Data Dictionary")
        target = relationships[sheet.attrib["{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"]]
        sheet_path = target.lstrip("/") if target.startswith("/") else "xl/" + target
        tables = OrderedDict()
        for row in ET.fromstring(archive.read(sheet_path)).findall("s:sheetData/s:row", NAMESPACE)[1:]:
            cells = {}
            for cell in row.findall("s:c", NAMESPACE):
                node = cell.find("s:v", NAMESPACE)
                value = node.text if node is not None else "".join(n.text or "" for n in cell.findall(".//s:t", NAMESPACE))
                if cell.attrib.get("t") == "s":
                    value = shared[int(value)]
                cells[re.sub(r"\d", "", cell.attrib["r"])] = (value or "").strip()
            if cells.get("A"):
                tables.setdefault(cells["A"], []).append(cells)
        return tables


def identifier(value):
    if not re.fullmatch(r"[a-z][a-z0-9_]*", value):
        raise ValueError("Unexpected identifier in workbook: " + value)
    return value


def default_value(field):
    value = field.get("H", "")
    if not value:
        return ""
    data_type = field["D"].upper()
    if data_type == "BOOLEAN":
        return " DEFAULT " + {"1": "true", "0": "false"}[value]
    if data_type.startswith(("VARCHAR", "CHAR")):
        # Several Excel defaults have only a trailing quote, e.g. DRAFT'.
        return " DEFAULT '" + value.strip("'").replace("'", "''") + "'"
    if value in ("now()", "CURRENT_DATE") or re.fullmatch(r"-?\d+(\.\d+)?", value):
        return " DEFAULT " + value
    raise ValueError("Unsupported workbook default: " + value)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workbook", type=Path)
    arguments = parser.parse_args()
    tables = read_dictionary(arguments.workbook)
    output = Path(__file__).resolve().parent / "Table Creations"
    output.mkdir(exist_ok=True)
    foreign_keys = ["-- Workbook foreign keys. Applied after every workbook table exists."]
    manifest = []
    for number, (table, fields) in enumerate(tables.items(), start=100):
        identifier(table)
        definitions = []
        manifest_fields = []
        for field in fields:
            column = identifier(field["C"])
            data_type = field["D"].upper()
            if not re.fullmatch(r"(BIGINT|INTEGER|SMALLINT|BOOLEAN|BYTEA|DATE|TIME|TIMESTAMPTZ|JSONB|VARCHAR\(\d+\)|CHAR\(\d+\)|NUMERIC\(\d+,\d+\))", data_type):
                raise ValueError("Unsupported workbook type: " + data_type)
            keys = [key.strip() for key in field.get("E", "").split(",")]
            identity = "Auto-increment" in field.get("I", "")
            definition = "    " + column + " " + data_type
            definition += " GENERATED ALWAYS AS IDENTITY" if identity else default_value(field)
            if "PK" in keys:
                definition += " PRIMARY KEY"
            elif field.get("G") == "No":
                definition += " NOT NULL"
            if "UQ" in keys:
                definition += " UNIQUE"
            definitions.append(definition)
            if field.get("F"):
                parent, parent_column = field["F"].split(".")
                identifier(parent)
                identifier(parent_column)
                constraint = "fk_" + table + "_" + column
                if len(constraint) > 63:
                    raise ValueError("Constraint exceeds PostgreSQL identifier limit: " + constraint)
                foreign_keys.append(f"""DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.{table}'::regclass
                   AND conname = '{constraint}') THEN
        ALTER TABLE public.{table} ADD CONSTRAINT {constraint}
            FOREIGN KEY ({column}) REFERENCES public.{parent} ({parent_column});
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_{table}_{column} ON public.{table} ({column});""")
            manifest_fields.append({"name": column, "type": data_type, "nullable": field.get("G") != "No" and "PK" not in keys,
                                    "identity": identity, "key": field.get("E", ""), "reference": field.get("F", ""),
                                    "default": field.get("H", ""), "remarks": field.get("J", "")})
        sql = "-- Source: design thinking Db and partition.xlsx / Data Dictionary\n"
        sql += f"CREATE TABLE IF NOT EXISTS public.{table}\n(\n" + ",\n".join(definitions) + "\n);\n"
        filename = f"{number:03d}_{table}.sql"
        (output / filename).write_text(sql, encoding="utf-8")
        manifest.append({"table": table, "script": filename, "columns": manifest_fields})
    (output / "199_WorkbookForeignKeys.sql").write_text("\n\n".join(foreign_keys) + "\n", encoding="utf-8")
    (Path(__file__).resolve().parent / "workbook-schema-manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Generated {len(tables)} table scripts, foreign keys, and the schema manifest.")


if __name__ == "__main__":
    main()
