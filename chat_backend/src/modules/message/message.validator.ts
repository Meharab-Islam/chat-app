import { z } from 'zod';

export const sendMessageSchema = z.object({
  chatId: z.string().min(1, 'Chat ID is required'),
  text: z.string().optional(),
  replyToId: z.string().optional(),
});

export const forwardMessageSchema = z.object({
  messageId: z.string().min(1, 'Original message ID is required'),
  targetChatIds: z.array(z.string().min(1)).min(1, 'At least one target chat required'),
  text: z.string().optional(),
});

export const reactMessageSchema = z.object({
  emoji: z.string().min(1, 'Emoji is required').max(32),
});

export type SendMessageInput = z.infer<typeof sendMessageSchema>;
export type ForwardMessageInput = z.infer<typeof forwardMessageSchema>;
export type ReactMessageInput = z.infer<typeof reactMessageSchema>;

