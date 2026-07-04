
//data/models/channels_model.dart


class ChannelModel {
  const ChannelModel({
    required this.id,
    required this.name,
    required this.category,
    required this.streamUrl,
    required this.logoUrl,
    required this.description,
    required this.quality,
    required this.isPremium,
  });

  final String id;
  final String name;
  final String category;
  final String streamUrl;
  final String logoUrl;
  final String description;
  final String quality;
  final int isPremium; // 0 = free, 1 = premium, 2 = basic

  factory ChannelModel.fromJson(Map<String, dynamic> json) => ChannelModel(
        id:          json['id']?.toString() ?? '',
        name:        json['name'] as String? ?? '',
        category:    json['category'] as String? ?? '',
        streamUrl:   json['streamUrl'] as String? ?? '',
        logoUrl:     json['logoUrl'] as String? ?? '',
        description: json['description'] as String? ?? '',
        quality:     json['quality'] as String? ?? 'HD',
        isPremium:   json['isPremium'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 
        'name': name, 
        'category': category,
        'streamUrl': streamUrl, 
        'logoUrl': logoUrl,
        'description': description, 
        'quality': quality,
        'isPremium': isPremium,
      };
}

class CategoryModel {
  const CategoryModel({required this.name, required this.icon});
  final String name;
  final String icon;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '📺',
      );
}

class BannerModel {
  const BannerModel({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.channelId,
  });
  final String title;
  final String subtitle;
  final String imageUrl;
  final String channelId;

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        title:     json['title'] as String? ?? '',
        subtitle:  json['subtitle'] as String? ?? '',
        imageUrl:  json['imageUrl'] as String? ?? '',
        channelId: json['channelId']?.toString() ?? '',
      );
}

class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.name,
    required this.price,
    required this.description,
    required this.badge,
    required this.features,
  });
  final String name;
  final String price;
  final String description;
  final String badge;
  final List<String> features;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlanModel(
        name:        json['name'] as String? ?? '',
        price:       json['price']?.toString() ?? '',
        description: json['description'] as String? ?? '',
        badge:       json['badge'] as String? ?? '',
        features:    List<String>.from((json['features'] as List<dynamic>?) ?? []),
      );
}

class UserProfileModel {
  const UserProfileModel({required this.email,required this.token, required this.plan});
  final String email;
  final String plan;
  final String token;

  Map<String, dynamic> toJson() => {'email': email,'token':token, 'plan': plan};

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        email: json['email'] as String? ?? '',
    		token: json['token'] as String? ?? '',
        plan:  json['plan'] as String? ?? 'Free',
      );
}

class ChannelCatalogModel {
  const ChannelCatalogModel({
    required this.channels,
    required this.categories,
    required this.banners,
    required this.plans,
  });

  final List<ChannelModel> channels;
  final List<CategoryModel> categories;
  final List<BannerModel> banners;
  final List<SubscriptionPlanModel> plans;

  factory ChannelCatalogModel.fromJson(Map<String, dynamic> json) =>
      ChannelCatalogModel(
        channels:   (json['channels'] as List<dynamic>? ?? [])
            .map((e) => ChannelModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        banners:    (json['banners'] as List<dynamic>? ?? [])
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        plans:      (json['plans'] as List<dynamic>? ?? [])
            .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
