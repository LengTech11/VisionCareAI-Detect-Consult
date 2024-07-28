<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Document;
use App\Models\Disease;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;


class ApiController extends Controller
{
    public function register(Request $request)
    {
        try
        {
            $validator = Validator::make($request->all(), [
                'first_name' => 'required|string|max:255',
                'last_name' => 'required|string|max:255',
                'email' => 'required|email|unique:users,email|max:255',
                'age' => 'required|integer',
                'gender' => 'required|integer',
                'password' => 'required|string|min:8',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $user = User::create([
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'email' => $request->email,
                'age' => $request->age,
                'gender' => $request->gender,
                'password' => Hash::make($request->password),
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'User created successfully',
                'token' => $user->createToken('API TOKEN')->plainTextToken
            ], 201);
        } catch (\Throwable $th) {
            return response()->json([
                'status' => 'error',
                'message' => $th->getMessage(),
            ], 500);
        }
    }

    public function login(Request $request)
    {
        try
        {
            $validator = Validator::make($request->all(), [
                'email' => 'required|email',
                'password' => 'required|string|min:8',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            if (!Auth::attempt($request->only('email', 'password'))) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid login details',
                ], 401);
            }

            $user = User::where('email', $request->email)->first();
            return response()->json([
                'status' => 'success',
                'message' => 'User logged in successfully',
                'token' => $user->createToken('API TOKEN')->plainTextToken
            ], 200);

        } catch (\Throwable $th) {
            return response()->json([
                'status' => 'error',
                'message' => $th->getMessage(),
            ], 500);
        }
    }

    public function profile(Request $request)
    {
        $userData  = auth()->user();
        return response()->json([
            'id' => auth()->user()->id,
            'status' => 'success',
            'message' => 'User profile',
            'data' => $userData,
        ], 200);
    }

    public function showDisease()
    {
        $diseases = Disease::select('id', 'title', 'description')->get();

        return response()->json([
            'status' => 'success',
            'data' => $diseases
        ], 200);
    }

    public function showDocument()
    {
        $doc = Document::with('disease')->get();
        $doc = $doc->map(function ($doc) {
            return [
                'id' => $doc->id,
                'file_name' => $doc->title,
                'url' => asset('storage/document/' . rawurlencode($doc->title)),
                'disease' => $doc->disease ? $doc->disease->title : null
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => $doc
        ], 200);
    }

    public function changePassword(Request $request)
    {
        try
        {
            $validator = Validator::make($request->all(), [
                'old_password' => 'required',
                'password' => 'required|string|min:8',
                'confirm_password' => 'required|same:password'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation error',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $user = $request->user();
            if(Hash::check($request->old_password, $user->password))
            {
                $user->update([
                    'password'=> Hash::make($request->password)
                ]);
                return response()->json([
                    'status' => 'success',
                    'message' => 'Password Successfully Updated',
                ], 200);
            }
            else
            {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Old password do not matched',
                ], 400);
            }

        } catch (\Throwable $th) {
            return response()->json([
                'status' => 'error',
                'message' => $th->getMessage(),
            ], 500);
        }
    }

}
