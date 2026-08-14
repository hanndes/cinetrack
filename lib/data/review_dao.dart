import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/review.dart';

class ReviewDao {
  final supabase = Supabase.instance.client;

  // Yorum ekle
  Future<int> addReview(int userId, int movieId, double rating, String? reviewText) async {
    final response = await supabase.from('reviews').insert({
      'user_id': userId,
      'movie_id': movieId,
      'rating': rating,
      'review_text': reviewText,
      'review_date': DateTime.now().toIso8601String(),
    }).select('id').single();
    return response['id'] as int;
  }

  // Bir filme ait tüm yorumları getir (en yeni üstte, kullanıcı adıyla birlikte)
  Future<List<Review>> getReviewsForMovie(int movieId) async {
    final maps = await supabase
        .from('reviews')
        .select('*, users(name)')
        .eq('movie_id', movieId)
        .order('review_date', ascending: false);

    return maps.map((map) {
      final flat = Map<String, dynamic>.from(map);
      flat['userName'] = map['users']?['name'];
      return Review.fromMap(flat);
    }).toList();
  }

  // Bir filmin ortalama puanı
  Future<double?> getAverageRating(int movieId) async {
    final maps = await supabase.from('reviews').select('rating').eq('movie_id', movieId);
    if (maps.isEmpty) return null;
    final total = maps.fold<double>(0, (sum, row) => sum + (row['rating'] as num).toDouble());
    return total / maps.length;
  }

  // Yorum sil (sadece kendi yorumunu silebilmesi için userId kontrolü de eklendi)
  Future<void> deleteReview(int reviewId, int userId) async {
    await supabase.from('reviews').delete().eq('id', reviewId).eq('user_id', userId);
  }

  // Yorum güncelle (sadece kendi yorumunu güncelleyebilmesi için userId kontrolü de eklendi)
  Future<void> updateReview(int reviewId, int userId, double rating, String? reviewText) async {
    await supabase.from('reviews').update({
      'rating': rating,
      'review_text': reviewText,
      'review_date': DateTime.now().toIso8601String(),
    }).eq('id', reviewId).eq('user_id', userId);
  }

  // Kullanıcının toplam kaç yorum yazdığını getir (Account/Profile istatistiği için)
  Future<int> getReviewCountForUser(int userId) async {
    final response = await supabase
        .from('reviews')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
    return response.count;
  }
}