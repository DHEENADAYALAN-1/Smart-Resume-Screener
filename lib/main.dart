import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pcaqxmikjvkxokjzwoqv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXF4bWlranZreG9ranp3b3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0ODUzNDYsImV4cCI6MjA5MTA2MTM0Nn0.2cm9X1C0gasqqV1HiQsG5Py_K2QrVPwKSukqoTKw9wY',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const Color _primaryBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
      ),
      home: const ResumeScreenerHome(),
    );
  }
}

class ResumeScreenerHome extends StatefulWidget {
  const ResumeScreenerHome({super.key});

  @override
  State<ResumeScreenerHome> createState() => _ResumeScreenerHomeState();
}

class _ResumeScreenerHomeState extends State<ResumeScreenerHome> {
  static const Color _primaryBlue = Color(0xFF1565C0);
  static const String _openRouterKey = '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';

  final TextEditingController _jobDescController = TextEditingController();
  final TextEditingController _resumeController = TextEditingController();
  String _matchScore = '—';
  String _feedback = 'Your feedback will appear here after screening.';
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _analyze() async {
    final jobDesc = _jobDescController.text.trim();
    final resumeText = _resumeController.text.trim();

    if (jobDesc.isEmpty) {
      setState(() => _statusMessage = '⚠️ Please paste a job description!');
      return;
    }
    if (resumeText.isEmpty) {
      setState(() => _statusMessage = '⚠️ Please paste your resume text!');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Analyzing with AI...';
      _matchScore = '—';
      _feedback = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterKey',
          'HTTP-Referer': 'https://smart-resume-screener.app',
          'X-Title': 'Smart Resume Screener',
        },
        body: jsonEncode({
         'model': 'openrouter/auto',
          'messages': [
            {
              'role': 'user',
              'content': '''You are a professional resume screener.

JOB DESCRIPTION:
$jobDesc

RESUME:
$resumeText

Analyze how well this resume matches the job description.
Respond with ONLY this JSON, no extra text, no markdown:
{"score": 75, "feedback": "3-4 sentences covering strengths, missing skills, and suggestions."}'''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content']
            .toString()
            .trim()
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final result = jsonDecode(text);
        setState(() {
          _matchScore = result['score'].toString();
          _feedback = result['feedback'];
          _isLoading = false;
          _statusMessage = '✅ Analysis complete!';
        });
      } else {
        throw Exception('Error: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Icon(Icons.description_outlined,
                      size: 56, color: _primaryBlue.withOpacity(0.9)),
                  const SizedBox(height: 20),
                  Text('Smart Resume Screener',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _primaryBlue,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Paste job description and resume to get your match score',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),

                  // Job Description
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Job Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _jobDescController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Paste the job description here...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue, width: 2),
                      ),
                      fillColor: Colors.grey.shade50,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resume Text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Your Resume (paste text here)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _resumeController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Copy and paste your resume text here...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue, width: 2),
                      ),
                      fillColor: Colors.grey.shade50,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Analyze Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _analyze,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.analytics_rounded, size: 22),
                      label: Text(
                        _isLoading ? _statusMessage : 'Analyze Resume',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  if (_statusMessage.isNotEmpty && !_isLoading) ...[
                    const SizedBox(height: 8),
                    Text(_statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('❌')
                            ? Colors.red : Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Results Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.smart_toy_outlined,
                              color: _primaryBlue, size: 22),
                          const SizedBox(width: 8),
                          Text('AI Feedback',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _primaryBlue)),
                        ]),
                        const SizedBox(height: 16),
                        Text('Match score',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('$_matchScore%',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                            fontSize: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _feedback.isEmpty
                              ? 'Your feedback will appear here after screening.'
                              : _feedback,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}git init