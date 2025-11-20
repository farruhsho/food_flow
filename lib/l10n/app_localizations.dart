import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('ru', ''),
    Locale('uz', ''),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'phone': 'Phone',
      'forgotPassword': 'Forgot Password?',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'logout': 'Logout',

      // Home
      'home': 'Home',
      'menu': 'Menu',
      'cart': 'Cart',
      'profile': 'Profile',
      'orders': 'Orders',
      'welcome': 'Welcome',
      'search': 'Search',
      'searchDishes': 'Search dishes...',

      // Menu
      'categories': 'Categories',
      'allCategories': 'All Categories',
      'addToCart': 'Add to Cart',
      'price': 'Price',
      'description': 'Description',

      // Cart
      'myCart': 'My Cart',
      'total': 'Total',
      'checkout': 'Checkout',
      'emptyCart': 'Your cart is empty',
      'remove': 'Remove',
      'quantity': 'Quantity',

      // Orders
      'myOrders': 'My Orders',
      'orderHistory': 'Order History',
      'orderDetails': 'Order Details',
      'orderStatus': 'Order Status',
      'pending': 'Pending',
      'preparing': 'Preparing',
      'ready': 'Ready',
      'delivering': 'Delivering',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',

      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'notifications': 'Notifications',
      'darkMode': 'Dark Mode',
      'english': 'English',
      'russian': 'Russian',
      'uzbek': 'Uzbek',

      // Admin
      'dashboard': 'Dashboard',
      'menuManagement': 'Menu Management',
      'userManagement': 'User Management',
      'analytics': 'Analytics',
      'reports': 'Reports',
      'totalOrders': 'Total Orders',
      'totalRevenue': 'Total Revenue',
      'totalUsers': 'Total Users',
      'addDish': 'Add Dish',
      'editDish': 'Edit Dish',
      'deleteDish': 'Delete Dish',

      // General
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'confirm': 'Confirm',
      'back': 'Back',
    },
    'ru': {
      // Auth
      'login': 'Войти',
      'register': 'Регистрация',
      'email': 'Электронная почта',
      'password': 'Пароль',
      'confirmPassword': 'Подтвердите пароль',
      'fullName': 'Полное имя',
      'phone': 'Телефон',
      'forgotPassword': 'Забыли пароль?',
      'dontHaveAccount': 'Нет аккаунта?',
      'alreadyHaveAccount': 'Уже есть аккаунт?',
      'signIn': 'Войти',
      'signUp': 'Зарегистрироваться',
      'logout': 'Выйти',

      // Home
      'home': 'Главная',
      'menu': 'Меню',
      'cart': 'Корзина',
      'profile': 'Профиль',
      'orders': 'Заказы',
      'welcome': 'Добро пожаловать',
      'search': 'Поиск',
      'searchDishes': 'Поиск блюд...',

      // Menu
      'categories': 'Категории',
      'allCategories': 'Все категории',
      'addToCart': 'Добавить в корзину',
      'price': 'Цена',
      'description': 'Описание',

      // Cart
      'myCart': 'Моя корзина',
      'total': 'Итого',
      'checkout': 'Оформить заказ',
      'emptyCart': 'Ваша корзина пуста',
      'remove': 'Удалить',
      'quantity': 'Количество',

      // Orders
      'myOrders': 'Мои заказы',
      'orderHistory': 'История заказов',
      'orderDetails': 'Детали заказа',
      'orderStatus': 'Статус заказа',
      'pending': 'Ожидание',
      'preparing': 'Готовится',
      'ready': 'Готово',
      'delivering': 'Доставляется',
      'delivered': 'Доставлено',
      'cancelled': 'Отменено',

      // Settings
      'settings': 'Настройки',
      'language': 'Язык',
      'notifications': 'Уведомления',
      'darkMode': 'Темная тема',
      'english': 'Английский',
      'russian': 'Русский',
      'uzbek': 'Узбекский',

      // Admin
      'dashboard': 'Панель управления',
      'menuManagement': 'Управление меню',
      'userManagement': 'Управление пользователями',
      'analytics': 'Аналитика',
      'reports': 'Отчеты',
      'totalOrders': 'Всего заказов',
      'totalRevenue': 'Общий доход',
      'totalUsers': 'Всего пользователей',
      'addDish': 'Добавить блюдо',
      'editDish': 'Редактировать блюдо',
      'deleteDish': 'Удалить блюдо',

      // General
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'add': 'Добавить',
      'yes': 'Да',
      'no': 'Нет',
      'ok': 'ОК',
      'error': 'Ошибка',
      'success': 'Успешно',
      'loading': 'Загрузка...',
      'confirm': 'Подтвердить',
      'back': 'Назад',
    },
    'uz': {
      // Auth
      'login': 'Kirish',
      'register': 'Ro\'yxatdan o\'tish',
      'email': 'Elektron pochta',
      'password': 'Parol',
      'confirmPassword': 'Parolni tasdiqlang',
      'fullName': 'To\'liq ism',
      'phone': 'Telefon',
      'forgotPassword': 'Parolni unutdingizmi?',
      'dontHaveAccount': 'Akkauntingiz yo\'qmi?',
      'alreadyHaveAccount': 'Akkauntingiz bormi?',
      'signIn': 'Kirish',
      'signUp': 'Ro\'yxatdan o\'tish',
      'logout': 'Chiqish',

      // Home
      'home': 'Bosh sahifa',
      'menu': 'Menyu',
      'cart': 'Savat',
      'profile': 'Profil',
      'orders': 'Buyurtmalar',
      'welcome': 'Xush kelibsiz',
      'search': 'Qidirish',
      'searchDishes': 'Taomlarni qidirish...',

      // Menu
      'categories': 'Kategoriyalar',
      'allCategories': 'Barcha kategoriyalar',
      'addToCart': 'Savatga qo\'shish',
      'price': 'Narx',
      'description': 'Tavsif',

      // Cart
      'myCart': 'Mening savatim',
      'total': 'Jami',
      'checkout': 'Buyurtma berish',
      'emptyCart': 'Savatingiz bo\'sh',
      'remove': 'O\'chirish',
      'quantity': 'Miqdor',

      // Orders
      'myOrders': 'Mening buyurtmalarim',
      'orderHistory': 'Buyurtmalar tarixi',
      'orderDetails': 'Buyurtma tafsilotlari',
      'orderStatus': 'Buyurtma holati',
      'pending': 'Kutilmoqda',
      'preparing': 'Tayyorlanmoqda',
      'ready': 'Tayyor',
      'delivering': 'Yetkazilmoqda',
      'delivered': 'Yetkazildi',
      'cancelled': 'Bekor qilindi',

      // Settings
      'settings': 'Sozlamalar',
      'language': 'Til',
      'notifications': 'Bildirishnomalar',
      'darkMode': 'Qorong\'i rejim',
      'english': 'Inglizcha',
      'russian': 'Ruscha',
      'uzbek': 'O\'zbekcha',

      // Admin
      'dashboard': 'Boshqaruv paneli',
      'menuManagement': 'Menyuni boshqarish',
      'userManagement': 'Foydalanuvchilarni boshqarish',
      'analytics': 'Tahlil',
      'reports': 'Hisobotlar',
      'totalOrders': 'Jami buyurtmalar',
      'totalRevenue': 'Umumiy daromad',
      'totalUsers': 'Jami foydalanuvchilar',
      'addDish': 'Taom qo\'shish',
      'editDish': 'Taomni tahrirlash',
      'deleteDish': 'Taomni o\'chirish',

      // General
      'save': 'Saqlash',
      'cancel': 'Bekor qilish',
      'delete': 'O\'chirish',
      'edit': 'Tahrirlash',
      'add': 'Qo\'shish',
      'yes': 'Ha',
      'no': 'Yo\'q',
      'ok': 'OK',
      'error': 'Xato',
      'success': 'Muvaffaqiyatli',
      'loading': 'Yuklanmoqda...',
      'confirm': 'Tasdiqlash',
      'back': 'Orqaga',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get fullName => translate('fullName');
  String get phone => translate('phone');
  String get forgotPassword => translate('forgotPassword');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get signIn => translate('signIn');
  String get signUp => translate('signUp');
  String get logout => translate('logout');

  String get home => translate('home');
  String get menu => translate('menu');
  String get cart => translate('cart');
  String get profile => translate('profile');
  String get orders => translate('orders');
  String get welcome => translate('welcome');
  String get search => translate('search');
  String get searchDishes => translate('searchDishes');

  String get categories => translate('categories');
  String get allCategories => translate('allCategories');
  String get addToCart => translate('addToCart');
  String get price => translate('price');
  String get description => translate('description');

  String get myCart => translate('myCart');
  String get total => translate('total');
  String get checkout => translate('checkout');
  String get emptyCart => translate('emptyCart');
  String get remove => translate('remove');
  String get quantity => translate('quantity');

  String get myOrders => translate('myOrders');
  String get orderHistory => translate('orderHistory');
  String get orderDetails => translate('orderDetails');
  String get orderStatus => translate('orderStatus');
  String get pending => translate('pending');
  String get preparing => translate('preparing');
  String get ready => translate('ready');
  String get delivering => translate('delivering');
  String get delivered => translate('delivered');
  String get cancelled => translate('cancelled');

  String get settings => translate('settings');
  String get language => translate('language');
  String get notifications => translate('notifications');
  String get darkMode => translate('darkMode');
  String get english => translate('english');
  String get russian => translate('russian');
  String get uzbek => translate('uzbek');

  String get dashboard => translate('dashboard');
  String get menuManagement => translate('menuManagement');
  String get userManagement => translate('userManagement');
  String get analytics => translate('analytics');
  String get reports => translate('reports');
  String get totalOrders => translate('totalOrders');
  String get totalRevenue => translate('totalRevenue');
  String get totalUsers => translate('totalUsers');
  String get addDish => translate('addDish');
  String get editDish => translate('editDish');
  String get deleteDish => translate('deleteDish');

  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get error => translate('error');
  String get success => translate('success');
  String get loading => translate('loading');
  String get confirm => translate('confirm');
  String get back => translate('back');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru', 'uz'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}