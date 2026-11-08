import { z } from 'zod';

export const reliefTypes = ['Sơ tán', 'Thực phẩm', 'Nước uống', 'Thuốc men', 'Cứu hộ'] as const;
export const urgencyLevels = ['Khẩn cấp', 'Cao', 'Trung bình'] as const;
const text = (max: number) => z.string().trim().max(max);
export const requestDataSchema = z.object({
  types: z.array(z.enum(reliefTypes)).min(1).max(reliefTypes.length).refine(v => new Set(v).size === v.length, 'Loại hỗ trợ bị lặp.'),
  people: z.number().int().min(1).max(2147483647),
  elderly: z.number().int().min(0), children: z.number().int().min(0),
  disabled: z.number().int().min(0), special: z.number().int().min(0),
  specialNotes: text(2000).default(''),
  description: text(4000).min(1, 'Hãy mô tả tình trạng cần hỗ trợ.'),
  urgency: z.enum(urgencyLevels), address: text(1000), landmark: text(2000),
  latitude: z.number().finite().min(-90).max(90),
  longitude: z.number().finite().min(-180).max(180),
  locationSource: z.enum(['gps', 'pin']),
  locationConfirmedAt: z.string().datetime({ offset: true }),
  clientActionAt: z.string().datetime({ offset: true }),
  evidenceIds: z.array(z.string().uuid()).default([]),
}).strict().superRefine((value, context) => {
  if (!value.address && !value.landmark) context.addIssue({ code: 'custom', path: ['address'], message: 'Nhập địa chỉ hoặc hướng dẫn nhận diện.' });
  for (const group of ['elderly', 'children', 'disabled', 'special'] as const) {
    if (value[group] > value.people) context.addIssue({ code: 'custom', path: [group], message: 'Số người trong nhóm vượt tổng số người.' });
  }
  if (new Set(value.evidenceIds).size !== value.evidenceIds.length) {
    context.addIssue({ code: 'custom', path: ['evidenceIds'], message: 'Ảnh đính kèm bị lặp.' });
  }
});
export type RequestData = z.infer<typeof requestDataSchema>;
export const submitSchema = z.object({ operationId: z.string().uuid(), data: requestDataSchema }).strict();
export const cancelSchema = z.object({ operationId: z.string().uuid(), confirmed: z.literal(true) }).strict();
export const reviewSchema = z.object({ operationId: z.string().uuid(), decision: z.enum(['valid', 'needs_info', 'invalid']), reason: text(2000).default('') }).strict()
  .refine(v => v.decision === 'valid' || v.reason.length > 0, 'Hãy ghi lý do hoặc nội dung cần bổ sung.');
export const reportSchema = z.object({ operationId: z.string().uuid(), reason: text(2000).min(1) }).strict();
export function expectedRevision(value: unknown) {
  const match = /^"([1-9]\d*)"$/.exec(typeof value === 'string' ? value : '');
  return match ? z.coerce.number().int().positive().max(2147483647).parse(match[1]) : null;
}
