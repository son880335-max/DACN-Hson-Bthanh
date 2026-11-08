import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import { ZodError } from 'zod';

export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string) { super(message); }
}

function validationMessage(issue: ZodError['issues'][number]): string {
  if (issue.code === 'custom' && /[\u00c0-\u1ef9]/.test(issue.message)) return issue.message;
  const field = [...issue.path].reverse().find(part => typeof part === 'string') as string | undefined;
  const messages: Record<string, string> = {
    types: 'Chọn ít nhất một loại hỗ trợ trong danh sách.',
    people: 'Nhập số người cần hỗ trợ bằng số nguyên dương.',
    elderly: 'Số người cao tuổi phải là số nguyên từ 0 đến tổng số người.',
    children: 'Số trẻ em phải là số nguyên từ 0 đến tổng số người.',
    disabled: 'Số người khuyết tật phải là số nguyên từ 0 đến tổng số người.',
    special: 'Số người cần chăm sóc đặc biệt phải là số nguyên từ 0 đến tổng số người.',
    specialNotes: 'Nội dung chăm sóc tối đa 2000 ký tự.',
    description: 'Nhập mô tả tình trạng, tối đa 4000 ký tự.',
    urgency: 'Chọn mức độ khẩn cấp trong danh sách.',
    address: 'Địa chỉ tối đa 1000 ký tự.',
    landmark: 'Hướng dẫn tìm đến tối đa 2000 ký tự.',
    latitude: 'Vĩ độ phải nằm trong khoảng -90 đến 90.',
    longitude: 'Kinh độ phải nằm trong khoảng -180 đến 180.',
    locationSource: 'Lấy vị trí hiện tại hoặc ghim trên bản đồ rồi xác nhận.',
    locationConfirmedAt: 'Xác nhận lại vị trí trước khi gửi.',
    clientActionAt: 'Chưa ghi nhận được thời điểm gửi. Kiểm tra ngày giờ thiết bị và thử lại.',
    capturedAt: 'Chưa đọc được thời điểm chụp ảnh. Hãy chụp lại hoặc tiếp tục không có ảnh.',
    evidenceIds: 'Danh sách ảnh chưa hợp lệ. Kiểm tra ảnh đính kèm và thử lại.',
    reason: 'Nhập lý do hoặc nội dung cần kiểm tra, tối đa 2000 ký tự.',
    decision: 'Chọn một kết quả xác minh trong danh sách.',
    confirmed: 'Xác nhận hủy yêu cầu trước khi tiếp tục.',
    phone: 'Nhập số điện thoại đã đăng ký.',
    password: 'Nhập mật khẩu tài khoản.',
  };
  return (field && messages[field]) || 'Kiểm tra lại thông tin và thử lại.';
}

@Catch()
export class ApiErrorFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse();
    const request = host.switchToHttp().getRequest();
    if (error instanceof ApiError) {
      return response.status(error.status).send({ code: error.code, message: error.message, requestId: request.id });
    }
    if (error instanceof ZodError) {
      return response.status(422).send({ code: 'VALIDATION_FAILED', message: 'Thông tin chưa hợp lệ.',
        fields: error.issues.map(i => ({ path: i.path.join('.'), message: validationMessage(i) })), requestId: request.id });
    }
    const status = error instanceof HttpException ? error.getStatus() : (error as { statusCode?: number })?.statusCode;
    if (status && status >= 400 && status < 500) {
      return response.status(status).send({ code: 'REQUEST_REJECTED', message: 'Không thể thực hiện yêu cầu này.', requestId: request.id });
    }
    console.error(JSON.stringify({ event: 'unhandled_error', requestId: request.id,
      name: error instanceof Error ? error.name : 'UnknownError' }));
    return response.status(500).send({ code: 'INTERNAL_ERROR', message: 'Hệ thống chưa xử lý được. Hãy giữ thông tin và thử lại.', requestId: request.id });
  }
}
