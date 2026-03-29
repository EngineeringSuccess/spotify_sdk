package de.minimalme.spotify_sdk

import com.google.gson.Gson
import com.spotify.android.appremote.api.SpotifyAppRemote
import io.flutter.plugin.common.MethodChannel

class SpotifyContentApi(spotifyAppRemote: SpotifyAppRemote?, result: MethodChannel.Result) : BaseSpotifyApi(spotifyAppRemote, result) {

    private val errorGetRecommendedContentItems = "getRecommendedContentItemsError"
    private val errorGetChildrenOfItem = "getChildrenOfItemError"

    private val contentApi = spotifyAppRemote?.contentApi

    internal fun getRecommendedContentItems(contentType: String?) {
        if (contentApi != null && !contentType.isNullOrBlank()) {
            contentApi.getRecommendedContentItems(contentType)
                    .setResultCallback { listItems ->
                        val items = listItems.items?.map { item ->
                            mapOf(
                                "id" to (item.id ?: ""),
                                "uri" to (item.uri ?: ""),
                                "title" to (item.title ?: ""),
                                "subtitle" to (item.subtitle ?: ""),
                                "image_uri" to (item.imageUri?.raw ?: ""),
                                "playable" to item.playable,
                                "has_children" to item.hasChildren
                            )
                        } ?: emptyList()
                        result.success(Gson().toJson(items))
                    }
                    .setErrorCallback { throwable ->
                        result.error(errorGetRecommendedContentItems, "error when getting recommended content items", throwable.toString())
                    }
        } else if (contentType.isNullOrBlank()) {
            result.error(errorGetRecommendedContentItems, "contentType has invalid format or is not set", "")
        } else {
            spotifyRemoteAppNotSetError()
        }
    }

    internal fun getChildrenOfItem(uri: String?, perPage: Int?, offset: Int?) {
        if (contentApi != null && !uri.isNullOrBlank()) {
            contentApi.getChildrenOfItem(
                    com.spotify.protocol.types.ListItem(uri, uri, null, null, null, false, false),
                    perPage ?: 20,
                    offset ?: 0
            )
                    .setResultCallback { listItems ->
                        val items = listItems.items?.map { item ->
                            mapOf(
                                "id" to (item.id ?: ""),
                                "uri" to (item.uri ?: ""),
                                "title" to (item.title ?: ""),
                                "subtitle" to (item.subtitle ?: ""),
                                "image_uri" to (item.imageUri?.raw ?: ""),
                                "playable" to item.playable,
                                "has_children" to item.hasChildren
                            )
                        } ?: emptyList()
                        result.success(Gson().toJson(items))
                    }
                    .setErrorCallback { throwable ->
                        result.error(errorGetChildrenOfItem, "error when getting children of item: $uri", throwable.toString())
                    }
        } else if (uri.isNullOrBlank()) {
            result.error(errorGetChildrenOfItem, "uri has invalid format or is not set", "")
        } else {
            spotifyRemoteAppNotSetError()
        }
    }
}
