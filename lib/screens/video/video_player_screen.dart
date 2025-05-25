import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/video.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillex/providers/comment_provider.dart';
import 'package:skillex/models/comment.dart';
import 'package:intl/intl.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> 
    with WidgetsBindingObserver {
  late YoutubePlayerController _controller;
  late Video _video;
  bool _isPlayerReady = false;
  final bool _isFullScreen = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _video = ModalRoute.of(context)!.settings.arguments as Video;
    _controller = YoutubePlayerController(
      initialVideoId: _video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
    // Fetch comments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure widget is still in the tree
        Provider.of<CommentProvider>(context, listen: false).fetchComments(_video.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Récupérer la vidéo depuis les arguments
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Video) {
      _video = arguments;
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    _controller.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
        _totalDuration = _controller.metadata.duration;
      });
    }

    if (_controller.value.isPlaying) {
      _updateProgress();
    }

    // Empêcher la capture d'écran et l'enregistrement
    if (_controller.value.isPlaying) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    }
  }

  void _updateProgress() {
    final position = _controller.value.position;
    final duration = _controller.metadata.duration;
    
    if (duration.inSeconds > 0) {
      final progress = (position.inSeconds / duration.inSeconds) * 100;
      setState(() {
        _currentPosition = Duration(seconds: (progress * duration.inSeconds / 100).round());
      });
      
      // Sauvegarder la progression
      Provider.of<ProgressProvider>(context, listen: false)
          .updateVideoProgress(
            videoId: _video.id,
            currentTime: position.inSeconds,
            totalDuration: duration.inSeconds,
          );
      
      // Marquer comme terminé si > 90%
      if (progress > 90) {
        Provider.of<ProgressProvider>(context, listen: false)
            .markVideoAsCompleted(_video.id, duration.inSeconds);
      }
    }
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Qualité vidéo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Auto'),
              onTap: () {
                _controller.setPlaybackRate(1.0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('HD'),
              onTap: () {
                _controller.setPlaybackRate(1.0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('SD'),
              onTap: () {
                _controller.setPlaybackRate(1.0);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vitesse de lecture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('0.5x'),
              onTap: () {
                _controller.setPlaybackRate(0.5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1.0x'),
              onTap: () {
                _controller.setPlaybackRate(1.0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1.5x'),
              onTap: () {
                _controller.setPlaybackRate(1.5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('2.0x'),
              onTap: () {
                _controller.setPlaybackRate(2.0);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler la vidéo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Contenu inapproprié'),
              onTap: () {
                _reportVideo('Contenu inapproprié');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Problème technique'),
              onTap: () {
                _reportVideo('Problème technique');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Autre'),
              onTap: () {
                _reportVideo('Autre');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reportVideo(String reason) {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour signaler une vidéo')),
      );
      return;
    }

    FirebaseFirestore.instance.collection('reports').add({
      'videoId': _video.id,
      'userId': userId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    }).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vidéo signalée avec succès')),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du signalement: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      child: Scaffold(
        appBar: _isFullScreen ? null : AppBar(
          title: Text(
            _video.title,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'quality':
                    _showQualityDialog();
                    break;
                  case 'speed':
                    _showSpeedDialog();
                    break;
                  case 'report':
                    _showReportDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'quality',
                  child: Row(
                    children: [
                      Icon(Icons.high_quality),
                      SizedBox(width: 8),
                      Text('Qualité'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'speed',
                  child: Row(
                    children: [
                      Icon(Icons.speed),
                      SizedBox(width: 8),
                      Text('Vitesse'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report),
                      SizedBox(width: 8),
                      Text('Signaler'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Lecteur vidéo
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Theme.of(context).primaryColor,
              onReady: () {
                setState(() {
                  _isPlayerReady = true;
                });
              },
              onEnded: (data) {
                final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
                progressProvider.markVideoAsCompleted(_video.id, _totalDuration.inSeconds);
              },
            ),
            
            if (!_isFullScreen) ...[
              // Informations de la vidéo
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et durée
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _video.channelTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _video.category,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Progression
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Votre progression',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${(_currentPosition.inSeconds / _totalDuration.inSeconds * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _currentPosition.inSeconds / _totalDuration.inSeconds,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Commentaires',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Comment Input Section (conditionally displayed)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.user != null) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Ajouter un commentaire...',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      maxLines: 3,
                                      minLines: 1,
                                      enabled: !_isPostingComment,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _isPostingComment
                                      ? const CircularProgressIndicator()
                                      : IconButton(
                                          icon: const Icon(Icons.send),
                                          onPressed: () async {
                                            if (_commentController.text.trim().isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Le commentaire ne peut pas être vide.')),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _isPostingComment = true;
                                            });
                                            final success = await Provider.of<CommentProvider>(context, listen: false).addComment(
                                              videoId: _video.id,
                                              text: _commentController.text.trim(),
                                              userId: authProvider.user!.uid,
                                              userName: authProvider.user!.displayName ?? 'Utilisateur Anonyme',
                                              userProfilePicUrl: authProvider.user!.photoURL,
                                            );
                                            if (success) {
                                              _commentController.clear();
                                            } else {
                                              if (mounted) {
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(Provider.of<CommentProvider>(context, listen: false).error ?? 'Erreur lors de l\'envoi')),
                                                );
                                              }
                                            }
                                            if (mounted) {
                                              setState(() {
                                                _isPostingComment = false;
                                              });
                                            }
                                          },
                                        ),
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox.shrink(); // Or a message "Log in to comment"
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Comments List Section
                      Consumer<CommentProvider>(
                        builder: (context, commentProvider, child) {
                          if (commentProvider.isLoading && commentProvider.comments.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (commentProvider.error != null && commentProvider.comments.isEmpty) {
                            return Center(child: Text(commentProvider.error!));
                          }
                          if (commentProvider.comments.isEmpty) {
                            return const Center(child: Text('Aucun commentaire pour le moment. Soyez le premier !'));
                          }

                          return Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: commentProvider.comments.length,
                                itemBuilder: (context, index) {
                                  final comment = commentProvider.comments[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: comment.userProfilePicUrl != null
                                              ? NetworkImage(comment.userProfilePicUrl!)
                                              : null,
                                          child: comment.userProfilePicUrl == null
                                              ? const Icon(Icons.person, size: 18)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.userName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Text(
                                                DateFormat('dd MMM yyyy, HH:mm').format(comment.timestamp.toDate()),
                                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(comment.text, style: const TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              if (commentProvider.hasMoreComments && !commentProvider.isLoading)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: TextButton(
                                    onPressed: () {
                                      Provider.of<CommentProvider>(context, listen: false).fetchMoreComments(_video.id);
                                    },
                                    child: const Text('Charger plus de commentaires'),
                                  ),
                                ),
                              if (commentProvider.isLoading && commentProvider.comments.isNotEmpty)
                                 const Padding(
                                   padding: EdgeInsets.all(8.0),
                                   child: Center(child: CircularProgressIndicator()),
                                 ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _commentController.dispose(); // Add this
    super.dispose();
  }
}