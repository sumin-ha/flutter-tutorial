package dev.foodmarks;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.*;

@Entity
public class Bookmark {
    @Id public UUID id = UUID.randomUUID();
    @Column(nullable = false, length = 100) public String title;
    @Column(nullable = false, length = 2000) public String snsUrl;
    @Column(length = 2000) public String thumbnailUrl;
    @Column(nullable = false, length = 2000) public String description;
    @ElementCollection(fetch = FetchType.EAGER)
    @OrderColumn(name = "tag_order")
    @Column(length = 20) public List<String> tags = new ArrayList<>();
    // User-entered address, never persist Google's formatted_address.
    @Column(nullable = false, length = 300) public String address;
    @Column(length = 300) public String placeId;
    public Double latitude;
    public Double longitude;
    public Instant coordinatesExpireAt;
    @Column(nullable = false) public Instant createdAt = Instant.now();
    @Column(nullable = false) public Instant updatedAt = Instant.now();
}
