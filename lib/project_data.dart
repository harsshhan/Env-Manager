import 'dart:convert';
import 'dart:isolate';


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;

class ProjectData extends StatefulWidget {
  final String project_id;
  final String projectName;
  final String access;
  final List<Map<String, dynamic>> envs;

  const ProjectData({super.key, 
    required this.project_id,
    required this.projectName,
    required this.envs,
    required this.access,
  });

  @override
  State<ProjectData> createState() => _ProjectDataState();
}

class _ProjectDataState extends State<ProjectData> {
  final _formKey = GlobalKey<FormState>();
  String keyName = '';
  String keyValue = '';
  String? apiUrl = dotenv.env['API_URL'];
  String developerEmail = '';

  final key = encrypt.Key.fromUtf8('adfkjdlasjfaldsjfdklfj');
  final IV = encrypt.IV.fromLength(16);

  Future<void> addEnv(String id, String keyName, String keyValue) async {
    try {

      final response = await http.post(Uri.parse('$apiUrl/addenv'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'project_id': id,
            'key_name': keyName,
            'key_value': keyValue
          }));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            widget.envs.add({
              'key_name': keyName,
              'key_value': keyValue,
            });
          });
        }
      } else {
        debugPrint('Failed to add ENV variable: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error occurred: $e');
    }
  }

  Future<void> deletedEnv(String projectId, String envId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/envdelete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'project_id': projectId, 'env_id': envId}),
      );

      if (response.statusCode == 200) {
        debugPrint('ENV deleted successfully');
      } else {
        debugPrint('Failed to delete ENV: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error occurred while deleting ENV: $e');
    }
  }

  


  @override
  void initState() {
    super.initState();
    apiUrl = dotenv.env['API_URL'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.projectName),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
      ),
      body: widget.envs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No ENV data availble for this project",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text("Try to add one", style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: widget.envs.length,
                itemBuilder: (context, index) {
                  final env = widget.envs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.vpn_key,
                        color: Colors.blueAccent,
                        size: 30,
                      ),
                      title: Text(
                        env['key_name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          env['key_value'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      trailing: widget.access == 'admin'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueAccent),
                                  onPressed: () {
                                    keyName = env['key_name'];
                                    keyValue = env['key_value'];
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Edit ENV Variable'),
                                          content: SizedBox(
                                            height: 160,
                                            width: 300,
                                            child: Form(
                                              key: _formKey,
                                              child: Column(
                                                children: [
                                                  TextFormField(
                                                    decoration: const InputDecoration(
                                                      labelText: 'Key Name',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    initialValue: keyName,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return "Please enter Key name";
                                                      }
                                                      return null;
                                                    },
                                                    onChanged: (value) {
                                                      setState(() {
                                                        keyName = value;
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(height: 20),
                                                  TextFormField(
                                                    decoration: const InputDecoration(
                                                      labelText: 'Key Value',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    initialValue: keyValue,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please enter Key Value';
                                                      }
                                                      return null;
                                                    },
                                                    onChanged: (value) {
                                                      setState(() {
                                                        keyValue = value;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Close'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  setState(() {
                                                    widget.envs[index] = {
                                                      'key_name': keyName,
                                                      'key_value': keyValue,
                                                    };
                                                  });
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: const Text('Submit'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete ENV Variable'),
                                          content: const Text(
                                              'Are you sure you want to delete this data?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                await deletedEnv(
                                                    widget.project_id,
                                                    env['env_id']);
                                                setState(() {
                                                  widget.envs.removeAt(index);
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Yes'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('No'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: widget.access == 'admin'
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Add New ENV Variable'),
                        content: SizedBox(
                          height: 160,
                          width: 300,
                          child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Key Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter Key name";
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        keyName = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Key Value',
                                        border: OutlineInputBorder()),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter Key Value';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        keyValue = value;
                                      });
                                    },
                                  )
                                ],
                              )),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close')),
                          TextButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    await addEnv(
                                        widget.project_id, keyName, keyValue);

                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    debugPrint("Failed to add");
                                  }
                                }
                              },
                              child: const Text('Submit'))
                        ],
                      );
                    });
              },
              shape: const CircleBorder(),
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.add),
            )
          : null,
    );
  }

}
