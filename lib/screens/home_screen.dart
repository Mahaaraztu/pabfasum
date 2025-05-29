import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pabfasum/screens/add_post_screen.dart';
import 'package:pabfasum/screens/detail_screen.dart';
import 'package:pabfasum/screens/edit_post_screen.dart';
import 'package:pabfasum/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentUserId;
  String? selectedCategory;
  //ambil dari add_post_screen
  List<String> categories = [
    'Jalan Rusak',
    'Marka Pudar',
    'Lampu Mati',
    'Trotoar Rusak',
    'Rambu Rusak',
    'Jembatan Rusak',
    'Sampah Menumpuk',
    'Saluran Tersumbat',
    'Sungai Tercemar',
    'Sampah Sungai',
    'Pohon Tumbang',
    'Taman Rusak',
    'Fasilitas Rusak',
    'Pipa Bocor',
    'Vandalisme',
    'Banjir',
    'Lainnya',
  ];

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} secs ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()));
  }

  //ambil dari https://pastebin.com/8BXgdv3M
  void _showCategoryFilter() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Semua Kategori'),
                  onTap: () => Navigator.pop(
                    context,
                    null,
                  ), // Null untuk memilih semua kategori
                ),
                const Divider(),
                ...categories.map(
                      (category) => ListTile(
                    title: Text(category),
                    trailing: selectedCategory == category
                        ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                        : null,
                    onTap: () => Navigator.pop(context, category),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedCategory =
            result; // Set kategori yang dipilih atau null untuk Semua Kategori
      });
    } else {
      // Jika result adalah null, berarti memilih Semua Kategori
      setState(() {
        selectedCategory =
        null; // Reset ke null untuk menampilkan semua kategori
      });
    }
  }

  //hapus data
  Future<void> _deletePost(String postId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      // Implement delete functionality
      FirebaseFirestore.instance.collection("posts").doc(postId).delete();
    }
  }

  //like post
  void _toggleLike(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef = FirebaseFirestore.instance.collection("posts").doc(postId);
    final postSnapshot = await postRef.get();

    if (postSnapshot.exists) {
      final data = postSnapshot.data()!;
      final likes = List<String>.from(data['likes'] ?? []);

      if (likes.contains(currentUser.uid)) {
        // Unlike the post
        likes.remove(currentUser.uid);
      } else {
        // Like the post
        likes.add(currentUser.uid);
      }

      await postRef.update({'likes': likes});
    }
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final TextEditingController commentController = TextEditingController();

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data!.docs;

                      if (comments.isEmpty) {
                        return const Center(
                          child: Text('No comments yet.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final commentData = comments[index].data();
                          final commentText = commentData['text'] ?? '';
                          final commenterName =
                              commentData['name'] ?? 'Anonymous';
                          final createdAt = commentData['createdAt']?.toDate();

                          return ListTile(
                            title: Text(commenterName),
                            subtitle: Text(commentText),
                            trailing: createdAt != null
                                ? Text(
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(createdAt),
                              style: const TextStyle(fontSize: 12),
                            )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null ||
                              commentController.text.isEmpty) {
                            return;
                          }

                          final commentText = commentController.text.trim();
                          commentController.clear();

                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();
                          final fullName =
                              userDoc.data()?['fullName'] ?? 'Anonymous';

                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .collection('comments')
                              .add({
                            'text': commentText,
                            'name': fullName,
                            'userId': uid,
                            'createdAt': Timestamp.now(),
                          });

                          final commentRef = FirebaseFirestore.instance
                              .collection("posts")
                              .doc(postId);
                          final commentSnapshot = await commentRef.get();

                          if (commentSnapshot.exists) {
                            final data = commentSnapshot.data()!;
                            final comments =
                            List<String>.from(data['comments'] ?? []);

                            if (!comments.contains(currentUser.uid)) {
                              comments.add(currentUser.uid);
                            }

                            await commentRef.update({'comments': comments});
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getPostsStream() {
    if (selectedCategory == null) {
      // Return all posts if no category is selected
      print("Filter by user id ${_currentUserId}");
      return FirebaseFirestore.instance
          .collection("posts")
          .where("userId", isNotEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Return posts filtered by the selected category
      print("Filter by Category ${selectedCategory}");
      return FirebaseFirestore.instance
          .collection("posts")
          .where("category", isEqualTo: selectedCategory)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () {
              signOut(context);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder(
          key: const ValueKey("postsStream"),
          stream: _getPostsStream(),
          builder: (context, snapshot) {
            print("Start");
            //print("Data " + snapshot.data!.docs.length.toString());
            print("Has Data ${snapshot.hasData}");
            print("Category ${selectedCategory}");
            //print("Has Data ${snapshot.hasData}");
            //print(snapshot.data?.docs);

            if (snapshot.hasError) {
              print("Trapped in has error ${!snapshot.hasData}");
              print("${snapshot.error}");

              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              print("Trapped in Laoding Data ${!snapshot.hasData}");
              //print("Data " + snapshot.data!.docs.length.toString());
              return const Center(child: CircularProgressIndicator());
            }



            final posts = snapshot.data!.docs;
            //.where((doc) {
            //   final data = doc.data();
            //   final category = data['category'] ?? 'Lainnya';
            //   return true;
            //   //return selectedCategory == null || selectedCategory == category;
            // });
            //.toList();

            if (posts.isEmpty) {
              return const Center(
                child: Text("Tidak ada laporan untuk kategori ini!"),
              );
            }

            //Script lengkap bagian ListView.builder
            //https://pastebin.com/kSXM5mTX
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final data = posts[index].data();
                final imageBase64 = data['image'];
                final description = data['description'];
                final createdAtStr = data['createdAt'];
                final fullName = data['fullName'] ?? 'Anonim';
                final latitude = data['latitude'] ?? 0.0;
                final longitude = data['longitude'] ?? 0.0;
                final category = data['category'] ?? 'Lainnya';
                final userId = data['userId'] ?? "";
                //parse ke DateTime
                final createdAt = DateTime.parse(createdAtStr);
                String heroTag =
                    'fasum-image-${createdAt.millisecondsSinceEpoch}';
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                            imageBase64: imageBase64,
                            description: description,
                            createdAt: createdAt,
                            fullName: fullName,
                            latitude: latitude,
                            longitude: longitude,
                            category: category,
                            heroTag: heroTag),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageBase64 != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: Image.memory(base64Decode(imageBase64),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatTime(createdAt),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        fullName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(category)
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      //Like Button
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              _toggleLike(posts[index]
                                                  .id); // Panggil fungsi toggleLike
                                            },
                                            child: Icon(
                                              Icons.thumb_up,
                                              size: 20,
                                              color: (data['likes'] ?? [])
                                                  .contains(
                                                  _currentUserId)
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                          ),
                                          if ((data['likes'] ?? []).length > 0)
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                    '${(data['likes'] ?? []).length}', // Tampilkan jumlah likes
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 16,
                                      ),
                                      //Comment Button
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Implement comment functionality
                                              _showComments(posts[index].id);
                                            },
                                            child: Icon(
                                              Icons.comment,
                                              size: 20,
                                              color: (data['comments'] ?? [])
                                                  .contains(
                                                  _currentUserId)
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                          ),
                                          if ((data['comments'] ?? []).length >
                                              0)
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                    '${(data['comments'] ?? []).length}', // Tampilkan jumlah komentar
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                        ],
                                      ),

                                      //Menu Edit dan Hapus
                                      if (_currentUserId == userId)
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(24),
                                                    ),
                                                  ),
                                                  builder: (context) {
                                                    return SafeArea(
                                                      child: Column(
                                                        mainAxisSize:
                                                        MainAxisSize.min,
                                                        children: [
                                                          //Menu Edit
                                                          ListTile(
                                                            leading: const Icon(
                                                                Icons.edit),
                                                            title: const Text(
                                                                'Edit'),
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context); //close the modal

                                                              // Navigate to edit screen or implement edit functionality
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                      EditPostScreen(
                                                                        postId:
                                                                        posts[index]
                                                                            .id,
                                                                        imageBase64:
                                                                        imageBase64,
                                                                        description:
                                                                        description,
                                                                        category:
                                                                        category,
                                                                      ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                          //Menu Hapus
                                                          ListTile(
                                                            leading: const Icon(
                                                                Icons.delete),
                                                            title: const Text(
                                                                'Delete'),
                                                            onTap: () async {
                                                              Navigator.pop(
                                                                  context);
                                                              _deletePost(
                                                                  posts[index]
                                                                      .id);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: const Icon(
                                                Icons.more_vert,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        )
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description ?? '',
                                style: const TextStyle(fontSize: 16),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "addPostButton",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddPostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}