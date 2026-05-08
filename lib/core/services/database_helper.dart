import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/birthday_model.dart';
import '../../models/todo_model.dart';
import '../../models/cafe_model.dart';
import '../../models/occasion_model.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import '../../models/payment_model.dart';

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
    await db.execute('''
      CREATE TABLE occasions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        occasionId INTEGER NOT NULL,
        name TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        splitMode TEXT NOT NULL,
        FOREIGN KEY (occasionId) REFERENCES occasions(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expenseId INTEGER NOT NULL,
        name TEXT NOT NULL,
        amountOwed REAL NOT NULL,
        paidAtCounter REAL NOT NULL,
        paidBack REAL NOT NULL,
        FOREIGN KEY (expenseId) REFERENCES expenses(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expenseId INTEGER NOT NULL,
        fromPerson TEXT NOT NULL,
        toPerson TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (expenseId) REFERENCES expenses(id)
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
    if(oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS occasions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          date TEXT,
          notes TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          occasionId INTEGER NOT NULL,
          name TEXT NOT NULL,
          totalAmount REAL NOT NULL,
          splitMode TEXT NOT NULL,
          FOREIGN KEY (occasionId) REFERENCES occasions(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS participants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          expenseId INTEGER NOT NULL,
          name TEXT NOT NULL,
          amountOwed REAL NOT NULL,
          paidAtCounter REAL NOT NULL,
          paidBack REAL NOT NULL,
          FOREIGN KEY (expenseId) REFERENCES expenses(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          expenseId INTEGER NOT NULL,
          fromPerson TEXT NOT NULL,
          toPerson TEXT NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (expenseId) REFERENCES expenses(id)
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

  //-----------Occasion CRUD--------------

  Future<int> insertOccasion(Occasion o) async {
    final db = await instance.database;
    return await db.insert('occasions', o.toMap());
  }

  Future<List<Occasion>> getAllOccasions() async {
    final db = await instance.database;
    final result =
        await db.query('occasions', orderBy: 'id DESC');
    return result.map((map) => Occasion.fromMap(map)).toList();
  }

  Future<int> updateOccasion(Occasion o) async {
    final db = await instance.database;
    return await db.update('occasions', o.toMap(),
        where: 'id = ?', whereArgs: [o.id]);
  }

  Future<int> deleteOccasion(int id) async {
    final db = await instance.database;
    // delete all expenses and participants under this occasion
    final expenses = await getExpensesByOccasion(id);
    for (final e in expenses) {
      await deleteExpense(e.id!);
    }
    return await db.delete('occasions',
        where: 'id = ?', whereArgs: [id]);
  }

  //-------------EXPENSE CRUD---------------

  Future<int> insertExpense(Expense e) async {
    final db = await instance.database;
    return await db.insert('expenses', e.toMap());
  }

  Future<List<Expense>> getExpensesByOccasion(int occasionId) async {
    final db = await instance.database;
    final result = await db.query('expenses',
        where: 'occasionId = ?', whereArgs: [occasionId]);
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense e) async {
    final db = await instance.database;
    return await db.update('expenses', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> deleteExpense(int id) async {
  final db = await instance.database;
  await db.delete('participants',
      where: 'expenseId = ?', whereArgs: [id]);
  await db.delete('payments',           // ✅ add this
      where: 'expenseId = ?', whereArgs: [id]);
  return await db.delete('expenses',
      where: 'id = ?', whereArgs: [id]);
}

  //-------------Participant CRUD---------------------

  Future<int> insertParticipant(Participant p) async {
    final db = await instance.database;
    return await db.insert('participants', p.toMap());
  }

  Future<List<Participant>> getParticipantsByExpense(
      int expenseId) async {
    final db = await instance.database;
    final result = await db.query('participants',
        where: 'expenseId = ?', whereArgs: [expenseId]);
    return result.map((map) => Participant.fromMap(map)).toList();
  }

  Future<int> updateParticipant(Participant p) async {
    final db = await instance.database;
    return await db.update('participants', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deleteParticipant(int id) async {
    final db = await instance.database;
    return await db.delete('participants',
        where: 'id = ?', whereArgs: [id]);
  }

  //--------------Payment CRUD-------------
  Future<int> insertPayment(Payment p) async {
    final db = await instance.database;
    return await db.insert('payments', p.toMap());
  }

  Future<List<Payment>> getPaymentsByExpense(int expenseId) async {
    final db = await instance.database;
    final result = await db.query('payments',
        where: 'expenseId = ?', whereArgs: [expenseId]);
    return result.map((map) => Payment.fromMap(map)).toList();
  }

  Future<int> deletePaymentsByExpense(int expenseId) async {
    final db = await instance.database;
    return await db.delete('payments',
        where: 'expenseId = ?', whereArgs: [expenseId]);
  }

  Future<int> deletePayment(int id) async {
    final db = await instance.database;
    return await db.delete('payments',
        where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}