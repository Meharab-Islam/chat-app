import { z } from 'zod';

export const createDirectChatSchema = z.object({
  recipientId: z.string().min(1, 'Recipient ID is required'),
});

export const createGroupChatSchema = z.object({
  name: z.string().min(1, 'Group name is required').max(100),
  memberIds: z.array(z.string()).min(1, 'At least one member is required'),
});

export type CreateDirectChatInput = z.infer<typeof createDirectChatSchema>;
export type CreateGroupChatInput = z.infer<typeof createGroupChatSchema>;

