import { Room, Track, ParticipantEvent } from 'livekit-client';

export interface MediaState {
  isMuted: boolean;
  isCameraOff: boolean;
  isScreenSharing: boolean;
}

export const syncParticipantMediaState = (room: Room | null): MediaState => {
  if (!room?.localParticipant) {
    return { isMuted: false, isCameraOff: false, isScreenSharing: false };
  }
  const lp = room.localParticipant;
  return {
    isMuted: !lp.isMicrophoneEnabled,
    isCameraOff: !lp.isCameraEnabled,
    isScreenSharing: lp.isScreenShareEnabled,
  };
};

export const toggleMicrophoneTrack = async (room: Room | null): Promise<boolean> => {
  if (!room?.localParticipant) return false;
  const lp = room.localParticipant;
  const shouldEnable = !lp.isMicrophoneEnabled;
  try {
    const micPub = lp.getTrackPublication(Track.Source.Microphone);
    if (micPub && micPub.track) {
      if (shouldEnable) {
        await micPub.unmute();
      } else {
        await micPub.mute();
      }
    } else {
      await lp.setMicrophoneEnabled(shouldEnable);
    }
  } catch (err) {
    console.warn('Failed to toggle mic:', err);
  }
  return !lp.isMicrophoneEnabled;
};

export const toggleCameraTrack = async (room: Room | null): Promise<boolean> => {
  if (!room?.localParticipant) return false;
  const lp = room.localParticipant;
  const shouldEnable = !lp.isCameraEnabled;
  try {
    const camPub = lp.getTrackPublication(Track.Source.Camera);
    if (camPub && camPub.track) {
      if (shouldEnable) {
        await camPub.unmute();
      } else {
        await camPub.mute();
      }
    } else {
      await lp.setCameraEnabled(shouldEnable);
    }
  } catch (err) {
    console.warn('Failed to toggle camera:', err);
  }
  return !lp.isCameraEnabled;
};

export const toggleScreenShareTrack = async (
  room: Room | null,
  isCurrentlySharing: boolean
): Promise<boolean> => {
  if (!room?.localParticipant) return false;
  const lp = room.localParticipant;
  const next = !isCurrentlySharing;
  try {
    await lp.setScreenShareEnabled(next);
    return next;
  } catch (err) {
    console.warn('Failed to toggle screen share:', err);
    return lp.isScreenShareEnabled;
  }
};

export const attachParticipantListeners = (
  room: Room,
  onStateChange: (state: MediaState) => void
) => {
  const sync = () => onStateChange(syncParticipantMediaState(room));
  room.localParticipant.on(ParticipantEvent.TrackMuted, sync);
  room.localParticipant.on(ParticipantEvent.TrackUnmuted, sync);
  room.localParticipant.on(ParticipantEvent.LocalTrackPublished, sync);
  room.localParticipant.on(ParticipantEvent.LocalTrackUnpublished, sync);

  return () => {
    room.localParticipant.off(ParticipantEvent.TrackMuted, sync);
    room.localParticipant.off(ParticipantEvent.TrackUnmuted, sync);
    room.localParticipant.off(ParticipantEvent.LocalTrackPublished, sync);
    room.localParticipant.off(ParticipantEvent.LocalTrackUnpublished, sync);
  };
};
