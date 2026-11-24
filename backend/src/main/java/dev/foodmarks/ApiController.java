package dev.foodmarks;

import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;

@RestController
@RequestMapping("/api")
public class ApiController {
    private final BookmarkService bookmarks;
    private final GeocodingService geocoding;
    public ApiController(BookmarkService bookmarks, GeocodingService geocoding) { this.bookmarks = bookmarks; this.geocoding = geocoding; }
    @GetMapping("/status") public Map<String, String> status() {
        return Map.of("status", "ok", "geocodingMode", geocoding.isDemo() ? "demo" : "google");
    }
    @GetMapping("/bookmarks") public List<Bookmark> list() { return bookmarks.list(); }
    @PostMapping("/bookmarks") @ResponseStatus(HttpStatus.CREATED)
    public Bookmark create(@Valid @RequestBody BookmarkInput input) { return bookmarks.save(null, input); }
    @PutMapping("/bookmarks/{id}") public Bookmark update(@PathVariable UUID id, @Valid @RequestBody BookmarkInput input) { return bookmarks.save(id, input); }
    @DeleteMapping("/bookmarks/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) { bookmarks.delete(id); }
    @PostMapping("/bookmarks/{id}/location") public Bookmark refresh(@PathVariable UUID id) { return bookmarks.refresh(id); }
    @GetMapping("/geocode") public List<GeocodingService.Candidate> geocode(@RequestParam String address) {
        if (address.isBlank() || address.length() > 300) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "주소는 1~300자로 입력해주세요.");
        return geocoding.search(address.strip());
    }
}
