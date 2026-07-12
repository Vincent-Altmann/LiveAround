const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

export function encodeGeoHash(
  latitude: number,
  longitude: number,
  precision = 9,
) {
  let isEven = true;
  let bit = 0;
  let character = 0;
  let geohash = '';
  let latitudeRange: [number, number] = [-90, 90];
  let longitudeRange: [number, number] = [-180, 180];

  while (geohash.length < precision) {
    if (isEven) {
      const mid = (longitudeRange[0] + longitudeRange[1]) / 2;
      if (longitude >= mid) {
        character = (character << 1) + 1;
        longitudeRange = [mid, longitudeRange[1]];
      } else {
        character <<= 1;
        longitudeRange = [longitudeRange[0], mid];
      }
    } else {
      const mid = (latitudeRange[0] + latitudeRange[1]) / 2;
      if (latitude >= mid) {
        character = (character << 1) + 1;
        latitudeRange = [mid, latitudeRange[1]];
      } else {
        character <<= 1;
        latitudeRange = [latitudeRange[0], mid];
      }
    }

    isEven = !isEven;

    if (bit < 4) {
      bit += 1;
    } else {
      geohash += base32[character];
      bit = 0;
      character = 0;
    }
  }

  return geohash;
}
