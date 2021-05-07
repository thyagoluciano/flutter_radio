package br.com.thyagoluciano.flutterradio.player

import android.content.Context
import android.media.AudioManager
import android.net.Uri
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.source.ExtractorMediaSource
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import org.greenrobot.eventbus.EventBus

class RadioService(val context: Context) : Player.EventListener, AudioManager.OnAudioFocusChangeListener {

    private val BANDWIDTH_METER = DefaultBandwidthMeter()
    private lateinit var exoPlayer: SimpleExoPlayer

    private lateinit var status: String
    private var streamUrl: String? = null

    fun onCreate() {

        val bandwidthMeter = DefaultBandwidthMeter()
        val trackSelectionFactory = AdaptiveTrackSelection.Factory(bandwidthMeter)
        val trackSelector = DefaultTrackSelector(trackSelectionFactory)

        exoPlayer = ExoPlayerFactory.newSimpleInstance(context, trackSelector)
        exoPlayer.addListener(this)

        status = PlaybackStatus.IDLE
    }

    private fun play(streamUrl: String) {
        this.streamUrl = streamUrl

        val dataSourceFactory = DefaultDataSourceFactory(context, "flutter_radio", BANDWIDTH_METER)
        val mediaSource = buildMediaSource(streamUrl, dataSourceFactory)

        exoPlayer.stop()
        exoPlayer.prepare(mediaSource)
        exoPlayer.playWhenReady = true
    }

    private fun buildMediaSource(streamUrl: String,
                                 dataSourceFactory: DefaultDataSourceFactory): MediaSource {
        val uri = Uri.parse(streamUrl)
        val type = Util.inferContentType(uri)
        return when (type) {
            C.TYPE_HLS   -> HlsMediaSource.Factory(dataSourceFactory).createMediaSource(uri)
            C.TYPE_OTHER -> ExtractorMediaSource.Factory(dataSourceFactory).createMediaSource(uri)
            else         -> {
                throw IllegalStateException("Unsupported type: $type")
            }
        }
    }

    private fun resume() {
        if (streamUrl != null)
            play(streamUrl!!)
    }

    private fun pause() {
        exoPlayer.playWhenReady = false
    }

    fun stop() {
        exoPlayer.stop()
    }

    fun playOrPause(url: String) {
        if (streamUrl != null && streamUrl == url) {
            if (!isPlaying()) {
                play(streamUrl!!)
            } else {
                pause()
            }
        } else {
            if (isPlaying()) {
                pause()
            }

            play(url)
        }
    }

    fun isPlaying() : Boolean {
        return this.status.equals(PlaybackStatus.PLAYING)
    }

    fun setVolume(volume: Float) {
        exoPlayer.setVolume(volume);
    }

    fun getStatus() : String = status

    override fun onAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                exoPlayer.volume = 0.8f
                resume()
            }

            AudioManager.AUDIOFOCUS_LOSS -> {
                stop();
            }

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                if (isPlaying()) pause()
            }

            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                if (isPlaying())
                    exoPlayer.volume = 0.1f
            }
        }
    }

    override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
        status = when(playbackState) {
            Player.STATE_BUFFERING -> PlaybackStatus.LOADING
            Player.STATE_ENDED -> PlaybackStatus.STOPPED
            Player.STATE_READY -> if (playWhenReady) PlaybackStatus.PLAYING else PlaybackStatus.PAUSED
            else -> PlaybackStatus.IDLE
        }

        if (EventBus.getDefault().hasSubscriberForEvent(String::class.java))
            EventBus.getDefault().post(status)
    }

    override fun onPlayerError(error: ExoPlaybackException?) {
        if (EventBus.getDefault().hasSubscriberForEvent(String::class.java))
            EventBus.getDefault().post(PlaybackStatus.ERROR)
    }

    override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters?) {}

    override fun onSeekProcessed() {}

    override fun onTracksChanged(trackGroups: TrackGroupArray?, trackSelections: TrackSelectionArray?) {}

    override fun onLoadingChanged(isLoading: Boolean) {}

    override fun onPositionDiscontinuity(reason: Int) {}

    override fun onRepeatModeChanged(repeatMode: Int) {}

    override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {}

    override fun onTimelineChanged(timeline: Timeline?, manifest: Any?, reason: Int) {}

}