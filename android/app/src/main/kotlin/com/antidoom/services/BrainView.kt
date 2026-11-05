package com.antidoom.services

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.view.View
import kotlin.math.min

/**
 * Original "brain buddy" mascot drawn with Canvas (no bitmap assets), so it is
 * crisp at any size. Its face reflects how close the user is to their limit.
 */
class BrainView(context: Context) : View(context) {

    enum class Mood { CALM, TIRED, FRIED }

    var mood: Mood = Mood.CALM
        set(value) {
            if (field != value) {
                field = value
                invalidate()
            }
        }

    private val body = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val fold = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val ink = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#2A1820")
        strokeCap = Paint.Cap.ROUND
    }
    private val shine = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
    private val blush = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()
    private val rect = RectF()

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val s = min(width, height).toFloat()
        val ox = (width - s) / 2f
        val oy = (height - s) / 2f
        fun x(f: Float) = ox + f * s
        fun y(f: Float) = oy + f * s

        val (bodyColor, foldColor, blushColor) = when (mood) {
            Mood.CALM -> Triple("#FFA8C5", "#E2789F", "#FF7BA6")
            Mood.TIRED -> Triple("#FFC27A", "#DE9246", "#FF9A5C")
            Mood.FRIED -> Triple("#FF7F7F", "#D24C4C", "#C93A3A")
        }
        body.color = Color.parseColor(bodyColor)
        fold.color = Color.parseColor(foldColor)
        fold.strokeWidth = s * 0.05f
        blush.color = Color.parseColor(blushColor)
        blush.alpha = 110

        // Lumpy brain silhouette: overlapping lobes
        val lobes = arrayOf(
            floatArrayOf(0.30f, 0.40f, 0.22f),
            floatArrayOf(0.50f, 0.30f, 0.24f),
            floatArrayOf(0.70f, 0.40f, 0.22f),
            floatArrayOf(0.30f, 0.62f, 0.22f),
            floatArrayOf(0.70f, 0.62f, 0.22f),
            floatArrayOf(0.50f, 0.66f, 0.24f),
        )
        for (l in lobes) canvas.drawCircle(x(l[0]), y(l[1]), l[2] * s, body)

        // Folds: center groove + a few squiggles
        path.reset()
        path.moveTo(x(0.50f), y(0.12f))
        path.quadTo(x(0.44f), y(0.22f), x(0.50f), y(0.32f))
        canvas.drawPath(path, fold)
        rect.set(x(0.16f), y(0.22f), x(0.34f), y(0.40f))
        canvas.drawArc(rect, 200f, 110f, false, fold)
        rect.set(x(0.66f), y(0.22f), x(0.84f), y(0.40f))
        canvas.drawArc(rect, 230f, 110f, false, fold)

        // Cheeks
        canvas.drawCircle(x(0.27f), y(0.66f), s * 0.07f, blush)
        canvas.drawCircle(x(0.73f), y(0.66f), s * 0.07f, blush)

        // Eyes
        val eyeY = y(0.53f)
        val lx = x(0.38f)
        val rx = x(0.62f)
        when (mood) {
            Mood.CALM -> {
                ink.style = Paint.Style.FILL
                canvas.drawCircle(lx, eyeY, s * 0.06f, ink)
                canvas.drawCircle(rx, eyeY, s * 0.06f, ink)
                canvas.drawCircle(lx + s * 0.02f, eyeY - s * 0.02f, s * 0.02f, shine)
                canvas.drawCircle(rx + s * 0.02f, eyeY - s * 0.02f, s * 0.02f, shine)
            }
            Mood.TIRED -> {
                ink.style = Paint.Style.STROKE
                ink.strokeWidth = s * 0.045f
                // half-closed lids
                rect.set(lx - s * 0.06f, eyeY - s * 0.05f, lx + s * 0.06f, eyeY + s * 0.05f)
                canvas.drawArc(rect, 0f, 180f, false, ink)
                rect.set(rx - s * 0.06f, eyeY - s * 0.05f, rx + s * 0.06f, eyeY + s * 0.05f)
                canvas.drawArc(rect, 0f, 180f, false, ink)
            }
            Mood.FRIED -> {
                ink.style = Paint.Style.STROKE
                ink.strokeWidth = s * 0.045f
                val d = s * 0.05f
                for (cx in floatArrayOf(lx, rx)) {
                    canvas.drawLine(cx - d, eyeY - d, cx + d, eyeY + d, ink)
                    canvas.drawLine(cx - d, eyeY + d, cx + d, eyeY - d, ink)
                }
            }
        }

        // Mouth
        ink.style = Paint.Style.STROKE
        ink.strokeWidth = s * 0.045f
        val my = y(0.70f)
        when (mood) {
            Mood.CALM -> {
                rect.set(x(0.43f), my - s * 0.06f, x(0.57f), my + s * 0.04f)
                canvas.drawArc(rect, 20f, 140f, false, ink)
            }
            Mood.TIRED -> canvas.drawLine(x(0.44f), my, x(0.56f), my, ink)
            Mood.FRIED -> {
                path.reset()
                path.moveTo(x(0.41f), my)
                path.quadTo(x(0.455f), my - s * 0.04f, x(0.50f), my)
                path.quadTo(x(0.545f), my + s * 0.04f, x(0.59f), my)
                canvas.drawPath(path, ink)
            }
        }
    }
}
