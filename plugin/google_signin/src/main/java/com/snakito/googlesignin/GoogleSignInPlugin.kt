// Plugin Android v2 do Snakito: obtém um Google ID token via Credential
// Manager (o caminho moderno, sem a lib deprecada de GoogleSignInClient).
// O token vai para o Supabase (grant_type=id_token) no lado GDScript.
package com.snakito.googlesignin

import android.util.Log
import androidx.core.content.ContextCompat
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class GoogleSignInPlugin(godot: Godot) : GodotPlugin(godot) {

    override fun getPluginName() = "GoogleSignIn"

    override fun getPluginSignals() = setOf(
        SignalInfo("token_recebido", String::class.java),
        SignalInfo("falhou", String::class.java),
    )

    /**
     * Abre o seletor de conta Google e emite `token_recebido(idToken)` ou
     * `falhou(codigo)`. `webClientId` = OAuth client do tipo WEB (o mesmo
     * configurado no provider do Supabase) — é a audiência do token.
     */
    @UsedByGodot
    fun solicitar(webClientId: String) {
        val atividade = activity
        if (atividade == null) {
            emitSignal("falhou", "sem_activity")
            return
        }
        val opcao = GetGoogleIdOption.Builder()
            .setServerClientId(webClientId)
            .setFilterByAuthorizedAccounts(false)
            .build()
        val pedido = GetCredentialRequest.Builder()
            .addCredentialOption(opcao)
            .build()
        CredentialManager.create(atividade).getCredentialAsync(
            atividade,
            pedido,
            null,
            ContextCompat.getMainExecutor(atividade),
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(result: GetCredentialResponse) {
                    val credencial = result.credential
                    if (credencial is CustomCredential &&
                        credencial.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
                    ) {
                        val token = GoogleIdTokenCredential.createFrom(credencial.data).idToken
                        emitSignal("token_recebido", token)
                    } else {
                        emitSignal("falhou", "credencial_inesperada")
                    }
                }

                override fun onError(e: GetCredentialException) {
                    Log.w("GoogleSignIn", "getCredential falhou", e)
                    emitSignal("falhou", e.javaClass.simpleName)
                }
            },
        )
    }
}
