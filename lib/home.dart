// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:convert';

import 'package:env_manager/login.dart';
import 'package:env_manager/project_data.dart';
import 'package:env_manager/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Home extends StatefulWidget {
  User userdata;

  Home({required this.userdata});
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> projects = [];
  String? apiUrl = '';
  bool isLoading = true;
  final TextEditingController projectNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String developerEmail = '';

  Future<void> fetchProjects(String email) async {
    final response = await http.post(Uri.parse('$apiUrl/getproject/$email'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<Map<String, dynamic>> fetchedProjects = [];
      for (var project in jsonResponse['projects']) {
        fetchedProjects.add(project);
      }

      if (mounted) {
        setState(() {
          projects = fetchedProjects;
          isLoading = false;
        });
      }

      print(projects);
    } else if (response.statusCode == 404) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> newProject(String email, String projectName) async {
    final response = await http.post(Uri.parse('$apiUrl/newproject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'project_name': projectName}));

    if (response.statusCode == 200) {
      final newProject = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          projects.add({
            'project_id': newProject['project_id'],
            'project_name': newProject['project_name'],
            'env': [],
            'access_level': 'admin'
          });
        });
      }
      // print(projects);
    } else {
      print('Failed to create project: ${response.body}');
    }
  }

  Future<void> deleteProject(String email, String project_id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/deleteproject'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'project_id': project_id}));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            projects
                .removeWhere((project) => project['project_id'] == project_id);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> addDeveloper(String project_id, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/add_developer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'project_id': project_id, 'email': email}),
      );
      final jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Developer added successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(jsonResponse['detail'] ?? 'An error occurred'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('An unexpected error occurred. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content:
                Text('An error occurred while trying to add the developer.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    apiUrl = dotenv.env['API_URL'] ?? '';
    fetchProjects(widget.userdata.email!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
            Text('ENV MANAGER'),
            IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("User Information"),
                          content: CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                NetworkImage(widget.userdata.photoURL!),
                          ),
                          actions: [
                            Center(
                                child: Column(
                              children: [
                                Text(widget.userdata.displayName!),
                                Text(widget.userdata.email!),
                              ],
                            )),
                            TextButton(
                                onPressed: () {
                                  Auth().signInWithGoogle();
                                  Navigator.of(context).pop();
                                },
                                child: Text('Switch to other account')),
                            TextButton(
                                onPressed: () {
                                  Auth().signOut();
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => LoginPage()),
                                      (Route<dynamic> route) => false);
                                },
                                child: Text('SignOut'))
                          ],
                        );
                      });
                },
                icon: CircleAvatar(
                  child: Icon(Icons.person),
                ))
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : projects.isEmpty
              ? Center(
                  child: Text("No projects Found"),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      String projectName = projects[index]['project_name'];
                      String access = projects[index]['access_level'];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Icon(
                            Icons.delete,
                            color: Colors.blueAccent,
                            size: 30,
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProjectData(
                                        project_id: projects[index]
                                            ['project_id'],
                                        projectName: projectName,
                                        envs: List<Map<String, dynamic>>.from(
                                            projects[index]['env']),
                                        access: access)));
                          },
                          title: Text(
                            projects[index]['project_name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: projects[index]['access_level'] == 'admin'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          _addDeveloper(context, projects[index]['project_id']);
                                        },
                                        
                                        icon: Icon(Icons.add)),
                                    IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.blueAccent),
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                    child: SizedBox(
                                                      height: 150,
                                                      width: 300,
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(16),
                                                        child:
                                                            Column(children: [
                                                          Text(
                                                            "Are you sure to delete project",
                                                            style: TextStyle(
                                                                fontSize: 15),
                                                          ),
                                                          SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            projectName,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  deleteProject(
                                                                      widget
                                                                          .userdata
                                                                          .email!,
                                                                      projects[
                                                                              index]
                                                                          [
                                                                          'project_id']);
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child: Text(
                                                                  'Yes',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          15),
                                                                ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child: Text(
                                                                    'No',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            15)),
                                                              ),
                                                            ],
                                                          ),
                                                        ]),
                                                      ),
                                                    ));
                                              });
                                        }),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Enter Project Name"),
                  content: TextField(
                    controller: projectNameController,
                    decoration: InputDecoration(hintText: 'Project Name'),
                  ),
                  actions: <Widget>[
                    TextButton(
                        onPressed: () {
                          String projectName = projectNameController.text;
                          if (projectName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Please enter Project Name')),
                            );
                            return;
                          } else {
                            newProject(widget.userdata.email!, projectName);
                            projectNameController.clear();
                            Navigator.pop(context);
                          }
                        },
                        child: Text("Save")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancel"))
                  ],
                );
              },
            );
          },
          child: Icon(Icons.add)),
    );
  }

  void _addDeveloper(BuildContext context,String project_id) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Add Developer "),
            content: SizedBox(
              height: 80,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                          labelText: "Developer Email",
                          border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter Email';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        developerEmail = value;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close')),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await addDeveloper(project_id, developerEmail);
                  },
                  child: Text('Add'))
            ],
          );
        });
  }

  
}
