package net.trtl3.tuneshell

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.Canvas
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
            PLACEHOLDER.matches(name) -> placeholder(name)
            NAME.matches(name) -> File(File(context!!.filesDir, "artwork"), name)
            else -> throw FileNotFoundException()
        }
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    /** A placeholder image drawn from a vector, once, in the cache folder. */
    private fun placeholder(name: String): File {
        val file = File(context!!.cacheDir, name)
        if (!file.exists()) {
            val icon = when (PLACEHOLDER.matchEntire(name)!!.groupValues[1]) {
                "album" -> R.drawable.ic_browse_album
                "artist" -> R.drawable.ic_browse_artist
                else -> R.drawable.ic_browse_track
            }
            val drawable = context!!.getDrawable(icon)!!
            val bitmap = Bitmap.createBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, SIZE, SIZE)
            drawable.draw(Canvas(bitmap))
            file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
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
        const val SIZE = 256
        val PLACEHOLDER = Regex("placeholder-(album|artist|track)\\.png")
        val NAME = Regex("[A-Za-z0-9_-]+\\.jpg")
    }
}
