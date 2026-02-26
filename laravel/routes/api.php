<?php

use App\Http\Controllers\NoteController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\VideoController;
use Illuminate\Support\Facades\Route;


Route::apiResource('notes', NoteController::class);

Route::apiResource('quizzes', QuizController::class);

Route::apiResource('videos', VideoController::class);