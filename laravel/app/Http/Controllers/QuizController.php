<?php

namespace App\Http\Controllers;

use App\Models\Quiz;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    public function index()
    {
        return response()->json(Quiz::latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'  => 'required|string|max:255',
            'grade' => 'sometimes|numeric|min:0|max:100',
        ]);

        $quiz = Quiz::create($validated);

        return response()->json($quiz, 201);
    }

    public function show(Quiz $quiz)
    {
        return response()->json($quiz);
    }

    public function update(Request $request, Quiz $quiz)
    {
        $validated = $request->validate([
            'name'  => 'sometimes|string|max:255',
            'grade' => 'sometimes|numeric|min:0|max:100',
        ]);
        if (isset($quiz->grade) && $quiz->grade > 0 && $request['grade'] != $quiz->grade) return response()->json(['error' => 'Grade is already set and cannot be updated.'], 409);

        $quiz->update($validated);

        return response()->json($quiz);
    }

    public function destroy(Quiz $quiz)
    {
        $quiz->delete();

        return response()->json(null, 204);
    }
}
