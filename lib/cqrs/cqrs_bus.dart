abstract class Command {
  const Command();
}

abstract class Query<R> {
  const Query();
}

abstract class CommandHandler<C extends Command> {
  Future<void> handle(C command);
}

abstract class QueryHandler<Q extends Query<R>, R> {
  Future<R> handle(Q query);
}

class CqrsBus {
  final Map<Type, dynamic> _commandHandlers = {};
  final Map<Type, dynamic> _queryHandlers = {};

  void registerCommandHandler<C extends Command>(CommandHandler<C> handler) {
    _commandHandlers[C] = handler;
  }

  void registerQueryHandler<Q extends Query<R>, R>(
    QueryHandler<Q, R> handler,
  ) {
    _queryHandlers[Q] = handler;
  }

  Future<void> execute<C extends Command>(C command) async {
    final handler = _commandHandlers[command.runtimeType] as CommandHandler<C>?;
    if (handler == null) {
      throw StateError('No command handler registered for ${command.runtimeType}');
    }
    await handler.handle(command);
  }

  Future<R> query<Q extends Query<R>, R>(Q query) async {
    final handler = _queryHandlers[query.runtimeType] as QueryHandler<Q, R>?;
    if (handler == null) {
      throw StateError('No query handler registered for ${query.runtimeType}');
    }
    return handler.handle(query);
  }
}
