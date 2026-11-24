package dev.foodmarks;

import jakarta.validation.constraints.*;
import java.net.URI;
import java.util.List;

public record BookmarkInput(
    @NotBlank @Size(max = 100) String title,
    @NotBlank @Size(max = 2000) String snsUrl,
    @NotNull @Size(max = 2000) String description,
    @NotNull @Size(max = 8) List<@NotBlank @Size(max = 20) String> tags,
    @NotBlank @Size(max = 300) String address,
    @NotBlank @Size(max = 300) String placeId,
    @Size(max = 2000) String thumbnailUrl
) {
    @AssertTrue(message = "사진 URL은 호스트가 있는 https:// 주소여야 합니다.")
    public boolean isValidThumbnailUrl() {
        if (thumbnailUrl == null || thumbnailUrl.isBlank()) return true;
        try {
            URI uri = URI.create(thumbnailUrl.strip());
            return "https".equalsIgnoreCase(uri.getScheme()) && uri.getHost() != null && uri.getUserInfo() == null;
        } catch (Exception ignored) { return false; }
    }
    @AssertTrue(message = "SNS URL은 호스트가 있는 https:// 주소여야 합니다.")
    public boolean isValidSnsUrl() {
        try {
            URI uri = URI.create(snsUrl);
            return "https".equalsIgnoreCase(uri.getScheme()) && uri.getHost() != null && uri.getUserInfo() == null;
        } catch (Exception ignored) { return false; }
    }
}
