using System.Data;
using JwtAuthenticationManager.Utility;
using Microsoft.AspNetCore.Identity;
using Npgsql;
using NpgsqlTypes;
using ReportAPI.Models;
using ReportAPI.Utility;

namespace ReportAPI.Services
{
    public class TeachersService : ITeachersService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TeachersService> _logger;
        private readonly IPasswordHasher<RegistrationModel> _passwordHasher;

        public TeachersService(IConfiguration configuration, ILogger<TeachersService> logger,
            IPasswordHasher<RegistrationModel> passwordHasher)
        {
            _configuration = configuration;
            _logger = logger;
            _passwordHasher = passwordHasher;
        }

        public async Task<Message<TeacherModel>> GetTeachersList(int pageNumber, int pageSize, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_page_number", NpgsqlDbType.Integer) { Value = pageNumber },
                    new NpgsqlParameter("p_page_size", NpgsqlDbType.Integer) { Value = pageSize }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, StoredProcedure.USP_GetTeachersList,
                    connectionString, cancellationToken))
                {
                    msg.DataList = new List<TeacherModel>();
                    foreach (DataRow row in dt.Rows)
                    {
                        msg.DataList.Add(TeacherMapper.MapTeacher(row));
                    }
                    msg.StatusCode = 200;
                    msg.IsSuccess = true;
                    msg.ReturnMessage = dt.Rows.Count > 0 ? "Records found successfully." : "No records found.";
                }
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(GetTeachersList));
            }
            return msg;
        }

        public async Task<Message<TeacherModel>> GetTeacherById(int teacherId, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_teacher_id", NpgsqlDbType.Integer) { Value = teacherId }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, StoredProcedure.USP_GetTeacherById,
                    connectionString, cancellationToken))
                {
                    if (dt.Rows.Count > 0)
                    {
                        msg.Data = TeacherMapper.MapTeacher(dt.Rows[0]);
                        msg.StatusCode = 200;
                        msg.IsSuccess = true;
                        msg.ReturnMessage = "Success.";
                    }
                    else
                    {
                        msg.StatusCode = 404;
                        msg.ReturnMessage = "Teacher not found.";
                    }
                }
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(GetTeacherById));
            }
            return msg;
        }

        public async Task<Message<TeacherModel>> SaveTeacher(RegistrationModel request, string role, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_first_name", NpgsqlDbType.Varchar) { Value = request.FirstName },
                    new NpgsqlParameter("p_last_name", NpgsqlDbType.Varchar) { Value = request.LastName },
                    new NpgsqlParameter("p_email", NpgsqlDbType.Varchar) { Value = request.Email },
                    new NpgsqlParameter("p_subject", NpgsqlDbType.Varchar) { Value = request.Subject ?? string.Empty },
                    new NpgsqlParameter("p_phone_number", NpgsqlDbType.Varchar) { Value = request.PhoneNumber ?? string.Empty },
                    new NpgsqlParameter("p_password_hash", NpgsqlDbType.Text) { Value = _passwordHasher.HashPassword(request, request.Password) },
                    new NpgsqlParameter("p_role", NpgsqlDbType.Varchar) { Value = role }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, StoredProcedure.USP_SaveTeacher,
                    connectionString, cancellationToken))
                {
                    if (dt.Rows.Count > 0)
                    {
                        msg.Data = TeacherMapper.MapTeacher(dt.Rows[0]);
                        msg.StatusCode = 201;
                        msg.IsSuccess = true;
                        msg.ReturnMessage = "Teacher saved successfully.";
                    }
                    else
                    {
                        msg.StatusCode = 404;
                        msg.ReturnMessage = "Teacher not found.";
                    }
                }
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(SaveTeacher));
            }
            return msg;
        }

        public async Task<Message<TeacherModel>> UpdateTeacher(UpdateTeacherRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_teacher_id", NpgsqlDbType.Integer) { Value = request.TeacherId },
                    new NpgsqlParameter("p_first_name", NpgsqlDbType.Varchar) { Value = request.FirstName },
                    new NpgsqlParameter("p_last_name", NpgsqlDbType.Varchar) { Value = request.LastName },
                    new NpgsqlParameter("p_email", NpgsqlDbType.Varchar) { Value = request.Email },
                    new NpgsqlParameter("p_subject", NpgsqlDbType.Varchar) { Value = request.Subject ?? string.Empty },
                    new NpgsqlParameter("p_phone_number", NpgsqlDbType.Varchar) { Value = request.PhoneNumber ?? string.Empty }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, StoredProcedure.USP_UpdateTeacher,
                    connectionString, cancellationToken))
                {
                    if (dt.Rows.Count > 0)
                    {
                        msg.Data = TeacherMapper.MapTeacher(dt.Rows[0]);
                        msg.StatusCode = 200;
                        msg.IsSuccess = true;
                        msg.ReturnMessage = "Teacher updated successfully.";
                    }
                    else
                    {
                        msg.StatusCode = 404;
                        msg.ReturnMessage = "Teacher not found.";
                    }
                }
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(UpdateTeacher));
            }
            return msg;
        }

        public async Task<Message<object>> DeleteTeacher(int teacherId, CancellationToken cancellationToken)
        {
            var msg = new Message<object>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_teacher_id", NpgsqlDbType.Integer) { Value = teacherId }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, StoredProcedure.USP_DeleteTeacher,
                    connectionString, cancellationToken))
                {
                    bool deleted = dt.Rows.Count > 0 && Convert.ToInt32(dt.Rows[0]["affected_count"]) > 0;
                    msg.StatusCode = deleted ? 200 : 404;
                    msg.IsSuccess = deleted;
                    msg.ReturnMessage = deleted ? "Teacher deleted successfully." : "Teacher not found.";
                }
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(DeleteTeacher));
            }
            return msg;
        }
    }
}
