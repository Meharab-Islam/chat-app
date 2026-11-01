import { z } from 'zod';

export const updateProfileSchema = z.object({
  name: z.string().min(1, 'Name cannot be empty').max(100).optional(),
  bio: z.string().max(250).optional(),
  status: z.string().max(100).optional(),
  avatarUrl: z.string().max(1000).optional(),
});

export const updateSettingsSchema = z.object({
  autoSaveToGallery: z.boolean().optional(),
  mediaAutoDownload: z.enum(['all', 'wifi_only', 'never']).optional(),
  notifications: z.boolean().optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type UpdateSettingsInput = z.infer<typeof updateSettingsSchema>;

