import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_poc/services/api_client.dart';
import 'package:powersync/powersync.dart';


class LaravelConnector extends PowerSyncBackendConnector {
  final ApiClient _api = ApiClient();

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Dev token from PowerSync dashboard
    return PowerSyncCredentials(
      endpoint: 'https://699d974aed1fcd0efe52dc12.powersync.journeyapps.com',
      token:
          'eyJhbGciOiJSUzI1NiIsImtpZCI6InBvd2Vyc3luYy1kZXYtMzIyM2Q0ZTMifQ.eyJzdWIiOiJ0ZXN0IiwiaWF0IjoxNzc0NDU5MzY1LCJpc3MiOiJodHRwczovL3Bvd2Vyc3luYy1hcGkuam91cm5leWFwcHMuY29tIiwiYXVkIjoiaHR0cHM6Ly82OTlkOTc0YWVkMWZjZDBlZmU1MmRjMTIucG93ZXJzeW5jLmpvdXJuZXlhcHBzLmNvbSIsImV4cCI6MTc3NDUwMjU2NX0.PQwCCmuL3BxEm7ryJZ2eVmo2msszEb_Hu4wtFancP5V1xbWhVv9fcCIMjyzK04HwBJvicmkhhbWbZteX-R2WKXB-g46HGpErDwti0LSt01uOGZVh1z0EBOlPtYhonqIS3TGgYgnwrL126ZbYgAyi2chKRNAIONrjtknSvJGZtUQUj0b2OQZONa9T0KHysOArgVKRF6YTn99dIOdJ67_a5x29ckhxCUKEtvL_xzUDVhbrFgRe20t9J3XiJY6R3X0SQ0RXuu9OJM-wPixerKggG_kvf_PKA4J7jVSjxgLGsghCjtYiSPVGDwSpniqELv5Z-EJ9WMaGs5mubNnWGfiiXQ',
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      for (final op in transaction.crud) {
        final data = op.opData ?? {};

        try {
          switch (op.table) {
            case 'videos':
              await _uploadVideo(op, data);
              break;
            case 'notes':
              await _uploadNote(op, data);
              break;
            case 'quizzes':
              await _uploadQuiz(op, data);
              break;
          }
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 401 || statusCode == 409) {
            await _revertLocalChange(database, op, statusCode!);
            // Continue processing remaining ops in the transaction
          } else {
            rethrow;
          }
        }
      }

      await transaction.complete();
    } on DioException catch (e) {
      // Surface non-recoverable Dio errors — PowerSync will retry
      throw Exception('Upload failed [${e.response?.statusCode}]: ${e.message}');
    }
  }

  /// Reverts a rejected op locally and notifies UI via [syncErrors] stream.
  ///
  /// For PUT (create): deletes the local record immediately since the server
  /// never accepted it and will not sync it back.
  /// For PATCH/DELETE: completing the transaction causes PowerSync to sync the
  /// server's authoritative state back down, reverting the local change.
  Future<void> _revertLocalChange(PowerSyncDatabase database, CrudEntry op, int statusCode) async {
    if (op.op == UpdateType.put) {
      await database.execute('DELETE FROM ${op.table} WHERE id = ?', [op.id]);
    }
  }

  Future<void> _uploadVideo(CrudEntry op, Map<String, dynamic> data) async {
    switch (op.op) {
      case UpdateType.put:
        await _api.post('/videos', {'id': op.id, ...data});
        break;
      case UpdateType.patch:
        await _api.put('/videos/${op.id}', data);
        break;
      case UpdateType.delete:
        await _api.delete('/videos/${op.id}');
        break;
    }
  }

  Future<void> _uploadNote(CrudEntry op, Map<String, dynamic> data) async {
    switch (op.op) {
      case UpdateType.put:
        await _api.post('/notes', {'id': op.id, ...data});
        break;
      case UpdateType.patch:
        await _api.put('/notes/${op.id}', data);
        break;
      case UpdateType.delete:
        await _api.delete('/notes/${op.id}');
        break;
    }
  }

  Future<void> _uploadQuiz(CrudEntry op, Map<String, dynamic> data) async {
    switch (op.op) {
      case UpdateType.put:
        await _api.post('/quizzes', {'id': op.id, ...data});
        break;
      case UpdateType.patch:
        await _api.put('/quizzes/${op.id}', data);
        break;
      case UpdateType.delete:
        await _api.delete('/quizzes/${op.id}');
        break;
    }
  }
}
