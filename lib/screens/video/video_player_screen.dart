import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/video.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    super.dispose();
  }
}