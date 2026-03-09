import 'package:get_it/get_it.dart';
import '../features/chat/data/services/chat_ws_service.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/chat_usecases.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';

void initChatModule(GetIt sl) {
  sl.registerLazySingleton(() => ChatWsService());
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(apiClient: sl()),
  );
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkMessagesReadUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(
    () => ChatBloc(
      getConversations: sl(),
      getMessages: sl(),
      sendMessageUseCase: sl(),
      markMessagesReadUseCase: sl(),
      createConversationUseCase: sl(),
      wsService: sl(),
    ),
  );
}
