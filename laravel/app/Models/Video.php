<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Video extends Model
{
    use HasUuids;
        protected $fillable = [
            'name',
            'offset',
            'is_completed',
        ];

    protected $casts = [
        'is_completed' => 'boolean',
        'offset'     => 'integer',
    ];
}
