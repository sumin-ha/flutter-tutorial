package dev.foodmarks;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.util.*;

@Service
@Transactional
public class BookmarkService {
    private final BookmarkRepository repository;
    private final GeocodingService geocoding;
    public BookmarkService(BookmarkRepository repository, GeocodingService geocoding) {
        this.repository = repository; this.geocoding = geocoding;
    }
    public List<Bookmark> list() {
        purge();
        return repository.findAll(org.springframework.data.domain.Sort.by("createdAt").descending());
    }
    public Bookmark save(UUID id, BookmarkInput input) {
        Bookmark b = id == null ? new Bookmark() : get(id);
        var c = geocoding.resolve(input.placeId()); // Client cannot submit arbitrary Google coordinates.
        b.title = input.title().strip(); b.snsUrl = input.snsUrl().strip();
        b.thumbnailUrl = input.thumbnailUrl() == null ? "" : input.thumbnailUrl().strip();
        b.description = input.description().strip(); b.address = input.address().strip();
        b.tags = new ArrayList<>(input.tags().stream().map(String::strip).distinct().toList());
        locate(b, c); b.updatedAt = Instant.now();
        return repository.save(b);
    }
    public Bookmark refresh(UUID id) {
        Bookmark b = get(id); locate(b, geocoding.resolve(b.placeId)); return repository.save(b);
    }
    private void locate(Bookmark b, GeocodingService.Candidate c) {
        b.placeId = c.placeId(); b.latitude = c.latitude(); b.longitude = c.longitude();
        b.coordinatesExpireAt = Instant.now().plus(Duration.ofDays(29)); // Margin before Google's 30-day limit.
    }
    private Bookmark get(UUID id) {
        return repository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "북마크를 찾을 수 없습니다."));
    }
    public void delete(UUID id) { repository.delete(get(id)); }
    // Purge hourly and on every list. A stopped server purges on the first request after restart.
    @Scheduled(fixedDelay = 3_600_000, initialDelay = 0)
    public void purge() { repository.purgeExpired(Instant.now()); }
}
