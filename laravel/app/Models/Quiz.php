<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Quiz extends Model
{
    use HasUuids;
    protected $fillable = [
        'name',
        'grade',
    ];

    protected $casts = [
        'grade' => 'decimal:2',
    ];
}
