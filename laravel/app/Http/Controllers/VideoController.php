<?php

namespace App\Http\Controllers;

use App\Models\Video;
use Illuminate\Http\Request;

class VideoController extends Controller
{
    public function index()
    {
        return response()->json(Video::latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'       => 'required|string|max:255',
            'offset'     => 'sometimes|integer|min:0',
            'is_completed' => 'sometimes|boolean',
        ]);

        $video = Video::create($validated);

        return response()->json($video, 201);
    }

    public function show(Video $video)
    {
        return response()->json($video);
    }

    public function update(Request $request, Video $video)
    {
        $validated = $request->validate([
            'name'       => 'sometimes|string|max:255',
            'offset'     => 'sometimes|integer|min:0',
            'is_completed' => 'sometimes|boolean',
        ]);

        $video->update($validated);

        return response()->json($video);
    }

    public function destroy(Video $video)
    {
        $video->delete();

        return response()->json(null, 204);
    }
}