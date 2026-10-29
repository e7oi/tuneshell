package net.trtl3.tuneshell

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

/**
 * Serves the stored artwork (`files/artwork/<hash>.jpg`) and a placeholder
 * image, read only, to the media browser of a car: Android Auto runs in
 * another process and cannot open a `file://` URI of the private folder
 * (FR-029). Only plain names are served, so no path can leave the folder.
 */
class ArtworkProvider : ContentProvider() {
    override fun onCreate() = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("read only")
        val name = uri.lastPathSegment ?: throw FileNotFoundException()
        val file = when {
            name == PLACEHOLDER -> placeholder()
            NAME.matches(name) -> File(File(context!!.filesDir, "artwork"), name)
            else -> throw FileNotFoundException()
        }
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    private fun placeholder(): File {
        val file = File(context!!.cacheDir, PLACEHOLDER)
        if (!file.exists()) {
            context!!.resources.openRawResource(R.drawable.ic_launcher_foreground).use { input ->
                file.outputStream().use { input.copyTo(it) }
            }
        }
        return file
    }

    override fun getType(uri: Uri) = "image/*"

    override fun query(
        uri: Uri,
        projection: Array<String>?,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?) = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<String>?,
    ) = 0

    private companion object {
        const val PLACEHOLDER = "placeholder.png"
        val NAME = Regex("[A-Za-z0-9_-]+\\.jpg")
    }
}
