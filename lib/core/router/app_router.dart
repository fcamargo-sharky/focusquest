import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusquest/models/task.dart';
import 'package:focusquest/models/routine.dart';
import 'package:focusquest/screens/main_shell.dart';
import 'package:focusquest/screens/home/home_screen.dart';
import 'package:focusquest/screens/tasks/tasks_screen.dart';
import 'package:focusquest/screens/tasks/add_task_screen.dart';
import 'package:focusquest/screens/timer/timer_screen.dart';
import 'package:focusquest/screens/stats/stats_screen.dart';
import 'package:focusquest/screens/profile/profile_screen.dart';
import 'package:focusquest/screens/routines/routines_screen.dart';
import 'package:focusquest/screens/routines/add_routine_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddTaskScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        AddTaskScreen(task: state.extra as Task),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timer',
                builder: (context, state) => const TimerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/routines',
        builder: (context, state) => const RoutinesScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddRoutineScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                AddRoutineScreen(routine: state.extra as Routine),
          ),
        ],
      ),
    ],
  );
});
