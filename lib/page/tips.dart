import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:video_player/video_player.dart';
import 'package:rana_jayeen/constants.dart' as AppColors;
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/page/MapScreen.dart';

class CarFixesTipsScreen extends StatefulWidget {
  static const routeName = '/fix';
  const CarFixesTipsScreen({super.key});

  @override
  _CarFixesTipsScreenState createState() => _CarFixesTipsScreenState();
}

class _CarFixesTipsScreenState extends State<CarFixesTipsScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 10;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final Map<String, bool> _subscriptionStatus = {};
  final Map<String, TextEditingController> _editControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  Timer? _debounce;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final ScrollController _scrollController = ScrollController();
  Query? _postsListenerRef; // For real-time updates
  Timer? _scrollDebounce; // For debouncing scroll events

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadItems();
    _loadSubscriptionStatus();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300), // Faster for better UX
      vsync: this,
    )..forward();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster scale animation
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _searchQuery.value = _searchController.text.trim().toLowerCase();
      _loadItems(refresh: true); // Reload with search filter
    });
  }

  Future<void> _loadSubscriptionStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final DatabaseReference subsRef = FirebaseDatabase.instance
          .ref()
          .child('driver_users')
          .child(currentUser.uid)
          .child('subscribers');
      final snapshot = await subsRef.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && mounted) {
        setState(() {
          data.forEach((key, value) {
            _subscriptionStatus[key] = value as bool? ?? false;
          });
        });
      }
    } catch (error) {
      debugPrint('Error loading subscription status: $error');
      _showErrorToast(AppLocalizations.of(context)!.subscriptionError);
    }
  }

  Future<void> _loadItems({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;
    setState(() => _isLoading = true);

    try {
      final postsRef = FirebaseDatabase.instance.ref().child('posts');
      final query = postsRef
          .orderByChild('timestamp')
          .limitToLast(_pageSize * (_page + 1));

      if (_postsListenerRef == null || refresh) {
        if (_postsListenerRef != null) {
          _postsListenerRef!.onValue.drain();
        }
        _postsListenerRef = query;
        _postsListenerRef!.onValue.listen((event) async {
          if (!mounted) return;
          final snapshot = event.snapshot;
          if (snapshot.exists) {
            final data = snapshot.value as Map<dynamic, dynamic>?;
            if (data == null) {
              setState(() {
                _hasMore = false;
                _isLoading = false;
              });
              return;
            }

            final List<Map<String, dynamic>> tempItems = [];
            for (var postEntry in data.entries) {
              final post = Map<String, dynamic>.from(postEntry.value);
              if (post['status'] == 'published') {
                post['id'] = postEntry.key;
                post['type'] =
                    post['contentType'] == 'video' ? 'video' : 'article';
                // Fetch userName from driver_users
                final userSnapshot = await FirebaseDatabase.instance
                    .ref()
                    .child('driver_users')
                    .child(post['userId'])
                    .once();
                final userData =
                    userSnapshot.snapshot.value as Map<dynamic, dynamic>?;
                post['userName'] = userData?['username'] ??
                    userData?['displayName'] ??
                    'Anonymous';
                tempItems.add(post);
                if (!_editControllers.containsKey(postEntry.key)) {
                  _editControllers[postEntry.key] = TextEditingController();
                }
                if (!_commentControllers.containsKey(postEntry.key)) {
                  _commentControllers[postEntry.key] = TextEditingController();
                }
              }
            }

            tempItems.sort((a, b) =>
                (b['timestamp'] as int).compareTo(a['timestamp'] as int));

            // Apply search filter
            final filteredItems = _searchQuery.value.isEmpty
                ? tempItems
                : tempItems.where((item) {
                    final title =
                        (item['title'] as String? ?? '').toLowerCase();
                    final description = (item['content'] as String? ??
                            item['description'] as String? ??
                            '')
                        .toLowerCase();
                    final tags = (item['tags'] as List<dynamic>?)
                            ?.join(' ')
                            .toLowerCase() ??
                        '';
                    return title.contains(_searchQuery.value) ||
                        description.contains(_searchQuery.value) ||
                        tags.contains(_searchQuery.value);
                  }).toList();

            setState(() {
              if (refresh) _items.clear();
              final start = _page * _pageSize;
              final end = start + _pageSize;
              _items.addAll(filteredItems.sublist(start,
                  end < filteredItems.length ? end : filteredItems.length));
              _page++;
              _hasMore = filteredItems.length > end;
              _isLoading = false;
            });
          } else {
            setState(() {
              _hasMore = false;
              _isLoading = false;
            });
          }
        }, onError: (error) {
          debugPrint('Error loading posts: $error');
          if (mounted) {
            setState(() => _isLoading = false);
            _showErrorToast(AppLocalizations.of(context)!.dataError);
          }
        });
      }
    } catch (error) {
      debugPrint('Error loading items: $error');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorToast(AppLocalizations.of(context)!.dataError);
      }
    }
  }

  void _onScroll() {
    if (_scrollDebounce?.isActive ?? false) return;
    _scrollDebounce = Timer(const Duration(milliseconds: 200), () {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadItems();
      }
    });
  }

  Future<void> _toggleSubscription(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorToast(AppLocalizations.of(context)!.loginRequired);
      return;
    }

    final loc = AppLocalizations.of(context)!;
    final isSubscribed = _subscriptionStatus[userId] ?? false;

    try {
      final DatabaseReference subsRef = FirebaseDatabase.instance
          .ref()
          .child('driver_users')
          .child(currentUser.uid)
          .child('subscribers')
          .child(userId);

      if (isSubscribed) {
        await subsRef.remove();
        setState(() => _subscriptionStatus[userId] = false);
        _showSuccessToast(loc.unsubscribed);
      } else {
        await subsRef.set(true);
        setState(() => _subscriptionStatus[userId] = true);
        _showSuccessToast(loc.subscribed);
      }
    } catch (error) {
      debugPrint('Error toggling subscription: $error');
      _showErrorToast(loc.subscriptionError);
    }
  }

  Future<void> _editPost(Map<String, dynamic> item) async {
    final loc = AppLocalizations.of(context)!;
    final titleController =
        TextEditingController(text: item['title'] as String?);
    final contentController =
        TextEditingController(text: item['content'] as String?);
    final tagsController = TextEditingController(
        text: (item['tags'] as List<dynamic>?)?.join(', ') ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          loc.editPost,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: loc.title,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.kPrimaryColor),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (item['contentType'] == 'article')
                TextFormField(
                  controller: contentController,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: loc.content,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.kPrimaryColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tagsController,
                decoration: InputDecoration(
                  labelText: loc.tags,
                  hintText: loc.tags_hint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.kPrimaryColor),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              loc.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'title': titleController.text.trim(),
                'content': item['contentType'] == 'article'
                    ? contentController.text.trim()
                    : null,
                'tags': tagsController.text
                    .trim()
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(loc.save),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      final postRef = FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(item['id'] as String);
      await postRef.update({
        'title': result['title'],
        if (result['content'] != null) 'content': result['content'],
        'tags': result['tags'],
      });
      _showSuccessToast(loc.postUpdated);
      await _loadItems(refresh: true);
    } catch (error) {
      debugPrint('Error updating post: $error');
      _showErrorToast(loc.postUpdateError);
    }
  }

  Future<void> _deletePost(Map<String, dynamic> item) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          loc.confirmDeletePost,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.red,
            fontSize: 20,
          ),
        ),
        content: Text(loc.confirmDeletePostMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              loc.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final postRef = FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(item['id'] as String);
      await postRef.remove();
      _showSuccessToast(loc.postDeleted);
      await _loadItems(refresh: true);
    } catch (error) {
      debugPrint('Error deleting post: $error');
      _showErrorToast(loc.postDeleteError);
    }
  }

  Future<void> _addComment(String postId, String userId) async {
    final loc = AppLocalizations.of(context)!;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorToast(loc.loginRequired);
      return;
    }

    final commentText = _commentControllers[postId]?.text.trim();
    if (commentText == null || commentText.isEmpty) {
      _showErrorToast(loc.emptyComment);
      return;
    }

    try {
      final commentRef = FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(postId)
          .child('comments')
          .push();
      await commentRef.set({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'content': commentText,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _commentControllers[postId]?.clear();
      _showSuccessToast(loc.commentPosted);
      await _loadItems(refresh: true);
    } catch (error) {
      debugPrint('Error posting comment: $error');
      _showErrorToast(loc.commentError);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> item) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorToast(AppLocalizations.of(context)!.loginRequired);
      return;
    }

    final loc = AppLocalizations.of(context)!;
    final postRef = FirebaseDatabase.instance
        .ref()
        .child('posts')
        .child(item['id'] as String)
        .child('likes')
        .child(currentUser.uid);

    try {
      final snapshot = await postRef.once();
      final isLiked = snapshot.snapshot.exists;

      if (isLiked) {
        await postRef.remove();
        _showSuccessToast(loc.unliked);
      } else {
        await postRef.set(true);
        _showSuccessToast(loc.liked);
      }
      await _loadItems(refresh: true);
    } catch (error) {
      debugPrint('Error toggling like: $error');
      _showErrorToast(loc.likeError);
    }
  }

  Future<void> _sharePost(Map<String, dynamic> item) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final shareUrl = 'https://ranajayeen.com/post/${item['id']}';
      final shareText = '${loc.sharePostText}\n${item['title']}\n$shareUrl';
      await Share.share(shareText, subject: item['title'] as String?);
      final postRef = FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(item['id'] as String);
      await postRef.update({
        'shares': (item['shares'] as int? ?? 0) + 1,
      });
      await _loadItems(refresh: true);
    } catch (error) {
      debugPrint('Error sharing post: $error');
      _showErrorToast(loc.shareError);
    }
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: "top",
      webBgColor: "linear-gradient(to right, #4caf50, #66bb6a)",
    );
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: "top",
      webBgColor: "linear-gradient(to right, #d32f2f, #ef5350)",
    );
  }

  void _showArticleDialog(Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;
    final comments = (item['comments'] as Map<dynamic, dynamic>?)
            ?.values
            .toList()
            .cast<Map<dynamic, dynamic>>() ??
        [];
    comments.sort(
        (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['userName'] as String? ?? loc.anonymous_user,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(item['timestamp'] as int),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'] as String? ?? loc.unknownLocation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (item['imageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item['imageUrl'] as String,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 220,
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 220,
                          color: Colors.grey[200],
                          child: const Icon(
                            Symbols.broken_image_rounded,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    item['content'] as String? ?? loc.unknownLocation,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (item['partName'] != null && item['partName'].isNotEmpty)
                    Row(
                      children: [
                        Text(
                          'Part: ${item['partName']} - Rating: ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < (item['rating'] as int? ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      loc.comments,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...comments.map((comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment['userName'] as String? ??
                                          loc.anonymous_user,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimestamp(
                                          comment['timestamp'] as int),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['content'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentControllers[item['id']],
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: loc.addComment,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.kPrimaryColor),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Symbols.send_rounded,
                            color: AppColors.kPrimaryColor),
                        onPressed: () {
                          _addComment(
                              item['id'] as String, item['userId'] as String);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  loc.ok,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    final loc = AppLocalizations.of(context)!;
    if (difference.inMinutes < 1) {
      return loc.just_now;
    } else if (difference.inHours < 1) {
      return loc.minutes_ago(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return loc.hours_ago(difference.inHours);
    } else if (difference.inDays < 30) {
      return loc.days_ago(difference.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          loc.carFixesTips,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.kPrimaryColor.withOpacity(0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/content_creation'),
        backgroundColor: AppColors.kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _isLoading && _items.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.kPrimaryColor,
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.noCarFixesTips,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadItems(refresh: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.kPrimaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(loc.retry),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.kPrimaryColor,
                          onRefresh: () => _loadItems(refresh: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _items.length && _hasMore) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      color: AppColors.kPrimaryColor,
                                    ),
                                  ),
                                );
                              }
                              final item = _items[index];
                              return _buildTutorialCard(item);
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: loc.search ?? 'Search car fixes...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(
              Symbols.search_rounded,
              color: Colors.grey[500],
            ),
            suffixIcon: ValueListenableBuilder<String>(
              valueListenable: _searchQuery,
              builder: (context, query, _) {
                return query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Symbols.clear_rounded,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery.value = '';
                          _loadItems(refresh: true);
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.kPrimaryColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;
    final isVideo = item['contentType'] == 'video';
    final isArticle = item['contentType'] == 'article';
    final userId = item['userId'] as String?;
    final isSubscribed = _subscriptionStatus[userId] ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = userId != null && userId == currentUser?.uid;
    final comments = (item['comments'] as Map<dynamic, dynamic>?)
            ?.values
            .toList()
            .cast<Map<dynamic, dynamic>>() ??
        [];
    comments.sort(
        (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    final isLiked = (item['likes'] as Map<dynamic, dynamic>?)
            ?.containsKey(currentUser?.uid) ??
        false;

    VideoPlayerController? videoController;
    if (isVideo && item['videoUrl'] != null) {
      if (!_videoControllers.containsKey(item['id'])) {
        _videoControllers[item['id']] = VideoPlayerController.networkUrl(
            Uri.parse(item['videoUrl'] as String))
          ..initialize().then((_) {
            _videoControllers[item['id']]?.setLooping(true);
            _videoControllers[item['id']]?.setVolume(0.0);
            _videoControllers[item['id']]?.play();
            if (mounted) setState(() {});
          }).catchError((error) {
            debugPrint('Error initializing video: $error');
            _showErrorToast(loc.videoLoadError);
          });
      }
      videoController = _videoControllers[item['id']];
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: isVideo
            ? () {
                if (videoController != null &&
                    videoController.value.isInitialized) {
                  setState(() {
                    videoController!.value.isPlaying
                        ? videoController.pause()
                        : videoController.play();
                  });
                }
              }
            : isArticle
                ? () => _showArticleDialog(item)
                : null,
        child: Card(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: isVideo &&
                              videoController != null &&
                              videoController.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: videoController.value.aspectRatio,
                              child: VideoPlayer(videoController),
                            )
                          : CachedNetworkImage(
                              imageUrl: item['imageUrl'] as String? ?? '',
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 220,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 220,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Symbols.broken_image_rounded,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                    if (isVideo)
                      Positioned.fill(
                        child: Center(
                          child: Icon(
                            videoController?.value.isPlaying ?? false
                                ? Symbols.pause_circle_rounded
                                : Symbols.play_circle_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 56,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isVideo
                                ? [Colors.blue.shade600, Colors.blue.shade400]
                                : [
                                    Colors.green.shade600,
                                    Colors.green.shade400
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isVideo ? loc.videos : loc.guides,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.kPrimaryColor,
                                  child: Text(
                                    (item['userName'] as String?)
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['userName'] as String? ??
                                        loc.anonymous_user,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTimestamp(item['timestamp'] as int),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['title'] as String? ?? loc.unknownLocation,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isVideo
                            ? (item['title'] as String? ?? loc.unknownLocation)
                            : (item['content'] as String? ??
                                loc.unknownLocation),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item['partName'] != null &&
                          item['partName'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(
                                'Part: ${item['partName']} - Rating: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < (item['rating'] as int? ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (item['tags'] != null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: (item['tags'] as List<dynamic>)
                              .map((tag) => Chip(
                                    label: Text(
                                      '#$tag',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Symbols.favorite_rounded
                                      : Symbols.favorite_border_rounded,
                                  color:
                                      isLiked ? Colors.red : Colors.grey[600],
                                  size: 24,
                                ),
                                onPressed: () => _toggleLike(item),
                              ),
                              Text(
                                '${(item['likes'] as Map<dynamic, dynamic>?)?.length ?? 0}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(
                                  Symbols.comment_rounded,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                                onPressed: () => _showArticleDialog(item),
                              ),
                              Text(
                                '${comments.length}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(
                                  Symbols.share_rounded,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                                onPressed: () => _sharePost(item),
                              ),
                              Text(
                                '${item['shares'] as int? ?? 0}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (userId != null && !isOwner && isArticle)
                            ElevatedButton(
                              onPressed: () => _toggleSubscription(userId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSubscribed
                                    ? Colors.grey[400]
                                    : AppColors.kPrimaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                isSubscribed ? loc.unsubscribe : loc.subscribe,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isOwner) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Symbols.edit_rounded,
                                color: AppColors.kPrimaryColor,
                                size: 24,
                              ),
                              onPressed: () => _editPost(item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Symbols.delete_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                              onPressed: () => _deletePost(item),
                            ),
                          ],
                        ),
                      ],
                      if (comments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ExpansionTile(
                          title: Text(
                            loc.comments,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 0),
                          trailing: comments.length > 2
                              ? Text(
                                  '+${comments.length - 2}',
                                  style: TextStyle(color: Colors.grey[600]),
                                )
                              : null,
                          onExpansionChanged: (expanded) {
                            if (expanded) _showArticleDialog(item);
                          },
                          children: comments
                              .take(2)
                              .map((comment) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment['userName']
                                                        as String? ??
                                                    loc.anonymous_user,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTimestamp(
                                                    comment['timestamp']
                                                        as int),
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment['content'] as String,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _commentControllers[item['id']],
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: loc.addComment,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.kPrimaryColor),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Symbols.send_rounded,
                              color: AppColors.kPrimaryColor,
                            ),
                            onPressed: () => _addComment(
                                item['id'] as String, item['userId'] as String),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, MapScreen.routeName),
                          icon: const Icon(
                            Symbols.location_on_rounded,
                            color: AppColors.kPrimaryColor,
                          ),
                          label: Text(
                            loc.findingProvider,
                            style:
                                const TextStyle(color: AppColors.kPrimaryColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.kPrimaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _editControllers.forEach((_, controller) => controller.dispose());
    _commentControllers.forEach((_, controller) => controller.dispose());
    _searchController.dispose();
    _debounce?.cancel();
    _searchQuery.dispose();
    _videoControllers.forEach((_, controller) => controller.dispose());
    _scrollController.dispose();
    _postsListenerRef?.onValue.drain();
    _scrollDebounce?.cancel();
    super.dispose();
  }
}
