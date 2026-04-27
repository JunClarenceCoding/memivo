import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/birthday_model.dart';
import '../models/todo_model.dart';
import '../models/cafe_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDB('memivo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE birthdays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        birthdate TEXT NOT NULL,
        notes TEXT,
        photoPath TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        dueDate TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cafes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drinkName TEXT NOT NULL,
        cafeName TEXT NOT NULL,
        drinkType TEXT NOT NULL,
        rating INTEGER NOT NULL,
        price TEXT,
        date TEXT,
        location TEXT,
        notes TEXT,
        photoPath TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          priority TEXT NOT NULL,
          status TEXT NOT NULL,
          dueDate TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cafes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          drinkName TEXT NOT NULL,
          cafeName TEXT NOT NULL,
          drinkType TEXT NOT NULL,
          rating INTEGER NOT NULL,
          price TEXT,
          date TEXT,
          location TEXT,
          notes TEXT,
          photoPath TEXT
        )
      ''');
    }
  }

  //-------------------BIRTHDAY CRUD-------------------

  //CREATE
  Future<int> insertBirthday(Birthday b) async {
    final db = await instance.database;
    return await db.insert('birthdays', b.toMap());
  }

  //READ ALL
  Future<List<Birthday>> getAllBirthdays() async {
    final db = await instance.database;
    final result = await db.query('birthdays', orderBy: 'name ASC');
    return result.map((map) => Birthday.fromMap(map)).toList();
  }

  //UPDATE
  Future<int> updateBirthday(Birthday b) async {
    final db = await instance.database;
    return await db.update(
      'birthdays',
       b.toMap(),
       where: 'id = ?',
       whereArgs: [b.id],
    );
  }

  //DELETE
  Future<int> deleteBirthday(int id) async {
    final db =  await instance.database;
    return await db.delete(
      'birthdays',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  //--------------------------TODO CRUD------------------------

  Future<int> insertTodo(Todo t) async {
    final db = await instance.database;
    return await db.insert('todos', t.toMap());
  }

  Future<List<Todo>> getAllTodos() async {
    final db = await instance.database;
    final result = await db.query('todos');
    return result.map((map) => Todo.fromMap(map)).toList();
  }

  Future<int> updateTodo(Todo t) async {
    final db = await instance.database;
    return await db.update(
      'todos',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await instance.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //------------------CAFE CRUD------------------------

  Future<int> insertCafe(Cafe c) async {
    final db = await instance.database;
    return await db.insert('cafes', c.toMap());
  }

  Future<List<Cafe>> getAllCafes() async {
    final db = await instance.database;
    final result = await db.query('cafes', orderBy: 'id DESC');
    return result.map((map) => Cafe.fromMap(map)).toList();
  }

  Future<int> updateCafe(Cafe c) async {
    final db = await instance.database;
    return await db.update(
      'cafes',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<int> deleteCafe(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cafes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}