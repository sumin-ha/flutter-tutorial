package dev.foodmarks;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import java.time.Instant;
import java.util.UUID;

public interface BookmarkRepository extends JpaRepository<Bookmark, UUID> {
    @Modifying(clearAutomatically = true)
    @Query("update Bookmark b set b.latitude = null, b.longitude = null, b.coordinatesExpireAt = null where b.coordinatesExpireAt <= :now")
    void purgeExpired(Instant now);
}
