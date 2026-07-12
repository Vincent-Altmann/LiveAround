import 'package:flutter_test/flutter_test.dart';
import 'package:livearound_mobile/src/data/mock_concert_repository.dart';
import 'package:livearound_mobile/src/domain/user_location.dart';
import 'package:livearound_mobile/src/livearound_app.dart';

void main() {
  testWidgets('shows LiveAround discovery screen', (tester) async {
    await tester.pumpWidget(
      LiveAroundApp(
        repository: MockConcertRepository(),
        locationLoader: () async => UserLocation.lyonFallback,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LiveAround'), findsOneWidget);
    expect(find.text('Concerts proches de vous'), findsOneWidget);
  });
}
