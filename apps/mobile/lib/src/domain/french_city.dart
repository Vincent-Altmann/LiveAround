/// Ville selectionnable manuellement quand l'utilisateur refuse la
/// geolocalisation (exigence du cadrage : ville renseignee manuellement).
/// Liste statique embarquee : pas d'appel reseau, fonctionne hors-ligne et
/// couvre les grandes agglomerations pour un service national.
class FrenchCity {
  const FrenchCity(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

const List<FrenchCity> frenchCities = [
  FrenchCity('Paris', 48.8566, 2.3522),
  FrenchCity('Marseille', 43.2965, 5.3698),
  FrenchCity('Lyon', 45.7640, 4.8357),
  FrenchCity('Toulouse', 43.6047, 1.4442),
  FrenchCity('Nice', 43.7102, 7.2620),
  FrenchCity('Nantes', 47.2184, -1.5536),
  FrenchCity('Montpellier', 43.6108, 3.8767),
  FrenchCity('Strasbourg', 48.5734, 7.7521),
  FrenchCity('Bordeaux', 44.8378, -0.5792),
  FrenchCity('Lille', 50.6292, 3.0573),
  FrenchCity('Rennes', 48.1173, -1.6778),
  FrenchCity('Reims', 49.2583, 4.0317),
  FrenchCity('Toulon', 43.1242, 5.9280),
  FrenchCity('Saint-Etienne', 45.4397, 4.3872),
  FrenchCity('Le Havre', 49.4944, 0.1079),
  FrenchCity('Grenoble', 45.1885, 5.7245),
  FrenchCity('Dijon', 47.3220, 5.0415),
  FrenchCity('Angers', 47.4784, -0.5632),
  FrenchCity('Nimes', 43.8367, 4.3601),
  FrenchCity('Clermont-Ferrand', 45.7772, 3.0870),
  FrenchCity('Aix-en-Provence', 43.5297, 5.4474),
  FrenchCity('Brest', 48.3904, -4.4861),
  FrenchCity('Tours', 47.3941, 0.6848),
  FrenchCity('Amiens', 49.8942, 2.2957),
  FrenchCity('Limoges', 45.8336, 1.2611),
  FrenchCity('Annecy', 45.8992, 6.1294),
  FrenchCity('Perpignan', 42.6887, 2.8948),
  FrenchCity('Besancon', 47.2378, 6.0241),
  FrenchCity('Metz', 49.1193, 6.1757),
  FrenchCity('Orleans', 47.9029, 1.9093),
  FrenchCity('Rouen', 49.4432, 1.0993),
  FrenchCity('Mulhouse', 47.7508, 7.3359),
  FrenchCity('Caen', 49.1829, -0.3707),
  FrenchCity('Nancy', 48.6921, 6.1844),
  FrenchCity('Avignon', 43.9493, 4.8055),
  FrenchCity('La Rochelle', 46.1603, -1.1511),
  FrenchCity('Poitiers', 46.5802, 0.3404),
  FrenchCity('Pau', 43.2951, -0.3708),
  FrenchCity('Bayonne', 43.4929, -1.4748),
  FrenchCity('Le Mans', 48.0061, 0.1996),
];
