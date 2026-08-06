import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String uid;
  final String createdAt;
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.uid = '',
    this.createdAt = '',
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        name: j['name'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        uid: (j['uid'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
      );
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isCustomer => role == 'customer';

  User copyWithName(String newName) => User(
      id: id,
      name: newName,
      email: email,
      role: role,
      uid: uid,
      createdAt: createdAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'uid': uid,
        'created_at': createdAt,
      };
}

class MenuItem {
  final int id;
  final String name;
  final String category;
  final String description;
  final double price;
  final bool available;
  final String image;
  final String photo;
  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.available,
    required this.image,
    required this.photo,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as int,
        name: j['name'] as String,
        category: j['category'] as String,
        description: (j['description'] ?? '') as String,
        price: (j['price'] as num).toDouble(),
        available: j['available'] as bool,
        image: (j['image'] ?? '') as String,
        photo: (j['photo'] ?? '') as String,
      );
}

class Booking {
  final int id;
  final String bookingDate;
  final String timeSlot;
  final String itemSummary;
  final double total;
  final String status;
  final String paymentStatus;
  final String createdAt;
  final String? uname;
  final String? uemail;
  final String itemsJson;
  Booking({
    required this.id,
    required this.bookingDate,
    required this.timeSlot,
    required this.itemSummary,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.uname,
    this.uemail,
    this.itemsJson = '[]',
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as int,
        bookingDate: j['booking_date'] as String,
        timeSlot: j['time_slot'] as String,
        itemSummary: (j['item_summary'] ?? '') as String,
        total: (j['total'] as num).toDouble(),
        status: j['status'] as String,
        paymentStatus: j['payment_status'] as String,
        createdAt: (j['created_at'] ?? '') as String,
        uname: j['uname'] as String?,
        uemail: j['uemail'] as String?,
        itemsJson: (j['items_json'] ?? '[]') as String,
      );

  bool get cancellable => status == 'pending' || status == 'confirmed';
}

class Txn {
  final int id;
  final String txnRef;
  final int? bookingId;
  final double amount;
  final String method;
  final String status;
  final String createdAt;
  final String? uname;
  Txn({
    required this.id,
    required this.txnRef,
    this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.uname,
  });

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as int,
        txnRef: j['txn_ref'] as String,
        bookingId: j['booking_id'] as int?,
        amount: (j['amount'] as num).toDouble(),
        method: j['method'] as String,
        status: j['status'] as String,
        createdAt: (j['created_at'] ?? '') as String,
        uname: j['uname'] as String?,
      );
}

class FeedbackItem {
  final int id;
  final int rating;
  final String comment;
  final bool hygieneIssue;
  final String status;
  final String response;
  final String createdAt;
  final String? uname;
  FeedbackItem({
    required this.id,
    required this.rating,
    required this.comment,
    required this.hygieneIssue,
    required this.status,
    required this.response,
    required this.createdAt,
    this.uname,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> j) => FeedbackItem(
        id: j['id'] as int,
        rating: j['rating'] as int,
        comment: (j['comment'] ?? '') as String,
        hygieneIssue: j['hygiene_issue'] as bool,
        status: j['status'] as String,
        response: (j['response'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
        uname: j['uname'] as String?,
      );
}

class Announcement {
  final int id;
  final String title;
  final String body;
  final String author;
  final String createdAt;
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as int,
        title: j['title'] as String,
        body: (j['body'] ?? '') as String,
        author: (j['author'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
      );
}

class InvoiceLine {
  final String name;
  final String image;
  final int qty;
  final double price;
  InvoiceLine({
    required this.name,
    required this.image,
    required this.qty,
    required this.price,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> j) => InvoiceLine(
        name: j['name'] as String,
        image: (j['image'] ?? '') as String,
        qty: j['qty'] as int,
        price: (j['price'] as num).toDouble(),
      );
}

class Invoice {
  final Booking booking;
  final List<InvoiceLine> lines;
  final Txn? txn;
  Invoice({required this.booking, required this.lines, this.txn});

  factory Invoice.fromJson(Map<String, dynamic> j) {
    final lines = (j['lines'] as List<dynamic>? ?? [])
        .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
        .toList();
    final t = j['txn'];
    return Invoice(
      booking: Booking.fromJson(j['booking'] as Map<String, dynamic>),
      lines: lines,
      txn: t == null ? null : Txn.fromJson(t as Map<String, dynamic>),
    );
  }
}

class Stats {
  final int users;
  final int items;
  final int todaysBookings;
  final double revenue;
  final int pending;
  final int newFb;
  final int hygieneFb;
  final double avgRating;
  final int reviewCount;
  Stats({
    required this.users,
    required this.items,
    required this.todaysBookings,
    required this.revenue,
    required this.pending,
    required this.newFb,
    required this.hygieneFb,
    required this.avgRating,
    required this.reviewCount,
  });

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        users: j['users'] as int,
        items: j['items'] as int,
        todaysBookings: j['todays_bookings'] as int,
        revenue: (j['revenue'] as num).toDouble(),
        pending: j['pending'] as int,
        newFb: j['new_fb'] as int,
        hygieneFb: j['hygiene_fb'] as int,
        avgRating: (j['avg_rating'] as num).toDouble(),
        reviewCount: j['review_count'] as int,
      );
}

class Api {
  Api._();

  static String? token;
  static User? user;

  static String get baseUrl {
    const host = String.fromEnvironment('API_HOST',
        defaultValue: kIsWeb ? '127.0.0.1' : '10.0.2.2');
    const isDefault = host == '127.0.0.1' || host == '10.0.2.2';
    const scheme = isDefault ? 'http' : 'https';
    const port = isDefault ? ':5000' : '';
    return '$scheme://$host$port';
  }

  static Map<String, String> _headers({bool json = false}) => {
        if (token != null) 'X-Auth-Token': token!,
        if (json) 'Content-Type': 'application/json',
      };

  static Future<dynamic> _get(String path) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not reach the server. Is the backend running? ($e)');
    }
  }

  static Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(json: true),
        body: body == null ? null : jsonEncode(body),
      );
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not reach the server. Is the backend running? ($e)');
    }
  }

  static dynamic _handle(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      data = {'error': 'Unexpected server response'};
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException((data is Map && data['error'] != null)
        ? data['error'] as String
        : 'Request failed (${res.statusCode})');
  }

  static Future<User> login(String email, String password) async {
    final d = await _post('/api/login', {'email': email, 'password': password});
    token = d['token'] as String;
    user = User.fromJson(d['user'] as Map<String, dynamic>);
    await _persistSession();
    return user!;
  }

  static Future<User> register(
      String name, String email, String password, String role) async {
    final d = await _post('/api/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    token = d['token'] as String;
    user = User.fromJson(d['user'] as Map<String, dynamic>);
    await _persistSession();
    return user!;
  }

  static Future<void> logout() async {
    try {
      await _post('/api/logout');
    } catch (_) {}
    token = null;
    user = null;
    await _clearSession();
  }

  // --- Session persistence (survives page refresh on web / app restarts) ---

  static const _kToken = 'kb_token';
  static const _kUser = 'kb_user';

  static Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token ?? '');
      await prefs.setString(_kUser, jsonEncode(user!.toJson()));
    } catch (_) {}
  }

  static Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.remove(_kUser);
    } catch (_) {}
  }

  /// Restores a previously saved session. Returns true if logged in.
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_kToken) ?? '';
      final savedUser = prefs.getString(_kUser);
      if (savedToken.isEmpty || savedUser == null) return false;
      token = savedToken;
      user = User.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
      await getMe();
      return true;
    } catch (_) {
      await _clearSession();
      token = null;
      user = null;
      return false;
    }
  }

  /// Fetches the current user profile with the saved token (validates session).
  static Future<User> getMe() async {
    final d = await _get('/api/me');
    user = User.fromJson(d['user'] as Map<String, dynamic>);
    return user!;
  }

  static Future<List<MenuItem>> getMenu() async {
    final d = await _get('/api/menu');
    return (d['items'] as List)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Announcement>> getAnnouncements() async {
    final d = await _get('/api/announcements');
    return (d['announcements'] as List)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> placeOrder(
    List<Map<String, int>> items,
    String bookingDate,
    String timeSlot,
    String method, {
    String? paymentName,
    String? paymentDetail,
  }) async {
    return (await _post('/api/order', {
      'items': items,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
      'method': method,
      if (paymentName != null) 'payment_name': paymentName,
      if (paymentDetail != null) 'payment_detail': paymentDetail,
    })) as Map<String, dynamic>;
  }

  static Future<List<Booking>> getBookings() async {
    final d = await _get('/api/bookings');
    return (d['bookings'] as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> cancelBooking(int id) async {
    await _post('/api/bookings/$id/cancel');
  }

  static Future<List<Txn>> getTransactions() async {
    final d = await _get('/api/transactions');
    return (d['transactions'] as List)
        .map((e) => Txn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Invoice> getInvoice(int bookingId) async {
    final d = await _get('/api/invoice/$bookingId');
    return Invoice.fromJson(d as Map<String, dynamic>);
  }

  static Future<List<FeedbackItem>> getMyFeedback() async {
    final d = await _get('/api/feedback');
    return (d['feedback'] as List)
        .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> postFeedback(
      int rating, String comment, bool hygiene) async {
    return (await _post('/api/feedback', {
      'rating': rating,
      'comment': comment,
      'hygiene_issue': hygiene,
    })) as Map<String, dynamic>;
  }

  static Future<void> updateName(String name) async {
    await _post('/api/profile', {'name': name});
  }

  static Future<void> changePassword(String current, String next) async {
    await _post('/api/profile', {
      'current_password': current,
      'new_password': next,
    });
  }

  static Future<Stats> getStats() async {
    final d = await _get('/api/admin/stats');
    return Stats.fromJson(d['stats'] as Map<String, dynamic>);
  }

  static Future<List<Booking>> getAdminBookings() async {
    final d = await _get('/api/admin/bookings');
    return (d['bookings'] as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> setBookingStatus(int id, String status) async {
    await _post('/api/admin/bookings/$id/status', {'status': status});
  }

  static Future<void> addMenuItem(String name, String category, String desc,
      double price, String image) async {
    await _post('/api/admin/menu', {
      'name': name,
      'category': category,
      'description': desc,
      'price': price,
      'image': image,
    });
  }

  static Future<bool> toggleItem(int id) async {
    final res = await _post('/api/admin/menu/$id/toggle');
    return res['available'] as bool? ?? false;
  }

  static Future<void> editItem(int id, String name, String category,
      String desc, double price, String image) async {
    await _post('/api/admin/menu/$id/edit', {
      'name': name,
      'category': category,
      'description': desc,
      'price': price,
      'image': image,
    });
  }

  static Future<void> deleteItem(int id) async {
    await _post('/api/admin/menu/$id/delete');
  }

  static Future<List<FeedbackItem>> getAdminFeedback() async {
    final d = await _get('/api/admin/feedback');
    return (d['feedback'] as List)
        .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> respondFeedback(int id, String response) async {
    await _post('/api/admin/feedback/$id/respond', {'response': response});
  }

  static Future<List<Announcement>> getAdminAnnouncements() async {
    final d = await _get('/api/admin/announcements');
    return (d['announcements'] as List)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addAnnouncement(String title, String body) async {
    await _post('/api/admin/announcements', {'title': title, 'body': body});
  }

  static Future<void> deleteAnnouncement(int id) async {
    await _post('/api/admin/announcements/$id/delete');
  }

  static Future<List<Txn>> getAdminTransactions() async {
    final d = await _get('/api/admin/transactions');
    return (d['transactions'] as List)
        .map((e) => Txn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<User>> getAdminUsers() async {
    final d = await _get('/api/admin/users');
    return (d['users'] as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> getStaffToday() async {
    return (await _get('/api/staff/today')) as Map<String, dynamic>;
  }
}
