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
  lateinit var streamUrl: String

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar): Unit {
      val channel = MethodChannel(registrar.messenger(), "flutter_radio")
      channel.setMethodCallHandler(FlutterRadioPlugin(registrar))
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result): Unit = when {

    call.method == "audioStart" -> {
      this.startPlayer()
    }

    call.method == "play" -> {
      streamUrl = call.argument("url")
      radioManager.playOrPause(streamUrl)
    }

    call.method == "pause" -> {
      radioManager.playOrPause(streamUrl)
    }

    call.method == "playOrPause" -> {
      radioManager.playOrPause(streamUrl)
    }

    else -> result.notImplemented()
  }

  private fun startPlayer() {
    val context: Context = mRegistrar.context()
    radioManager = RadioManager(context)
    radioManager.initPlayer()
  }

}
