import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';


class BusinessCardItem extends StatelessWidget {
  final BusinessCard businessCard;
  final VoidCallback onTap;

  const BusinessCardItem({
    super.key,
    required this.businessCard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Business card image thumbnail or placeholder
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image:
                      businessCard.imagePath != null
                          ? DecorationImage(
                            image: FileImage(File(businessCard.imagePath!)),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    businessCard.imagePath == null
                        ? const Icon(
                          Icons.contact_mail,
                          size: 40,
                          color: Colors.grey,
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessCard.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessCard.jobTitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessCard.company,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
