import 'package:flutter/material.dart';

class FileUploadBox extends StatelessWidget {
  final String? selectedFileName;
  final String fileType;
  final VoidCallback onClear;
  final VoidCallback onPick;

  const FileUploadBox({
    super.key,
    required this.selectedFileName,
    required this.fileType,
    required this.onClear,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final extensions = fileType == 'video'
        ? ['mp4', 'mov', 'avi', 'webm']
        : ['pdf', 'doc', 'docx'];
    final extensionsText = extensions.map((e) => '.$e').join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFileName != null)
            Row(
              children: [
                Icon(
                  fileType == 'video'
                      ? Icons.video_file
                      : Icons.insert_drive_file,
                  color: fileType == 'video' ? Colors.purple : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedFileName!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: onClear,
                ),
              ],
            )
          else
            const Text('Chưa chọn tệp', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPick,
              icon: Icon(Icons.upload_file),
              label: Text('Chọn tệp ($extensionsText)'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fileType == 'video' ? 'Tối đa 500MB' : 'Tối đa 50MB',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
