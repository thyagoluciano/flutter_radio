package br.com.thyagoluciano.flutterradio

import android.content.Context
import br.com.thyagoluciano.flutterradio.player.RadioManager
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar

class FlutterRadioPlugin(val mRegistrar: Registrar): MethodCallHandler {

  lateinit var radioManager: RadioManager

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar): Unit {
      val channel = MethodChannel(registrar.messenger(), "flutter_radio")
      channel.setMethodCallHandler(FlutterRadioPlugin(registrar))
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result): Unit {
      when {
        call.method.equals("audioStart") -> {
          this.startPlayer()
          result.success(null)
        }
        call.method.equals("play") -> {
          val url: String? = call.argument("url")
          if (url != null)
            radioManager.playOrPause(url)
          result.success(null)
        }
        call.method.equals("pause") -> {
          val url: String? = call.argument("url")
          if (url != null)
            radioManager.playOrPause(url)
          result.success(null)
        }
        call.method.equals("playOrPause") -> {
          val url: String? = call.argument("url")
          if (url != null)
            radioManager.playOrPause(url)
          result.success(null)
        }
        call.method.equals("stop") -> {
          radioManager.stop()
          result.success(null)
        }
        call.method.equals("isPlaying") -> {
            val play = isPlaying()
            result.success(play)
        }
        call.method.equals("setVolume") -> {
            val volume: Float = call.argument("volume")
            radioManager.setVolume(volume);
        }
        else -> result.notImplemented()
      }
  }

  private fun startPlayer() {
    val context: Context = mRegistrar.context()
    radioManager = RadioManager(context)
    radioManager.initPlayer()
  }

  private fun isPlaying() : Boolean {
      return radioManager.isPlaying()
  }

}
