package br.com.thyagoluciano.flutterradio.player

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import org.greenrobot.eventbus.EventBus

class RadioManager(private val context: Context) {

    private var instance: RadioManager? = null

    private var service = RadioService(context)

    private var serviceBound = false

    fun initPlayer() {
        service.onCreate()
    }

    fun playOrPause(streamUrl: String) {
        service.playOrPause(streamUrl)
    }

    fun isPlaying(): Boolean {
        return service.isPlaying()
    }
}