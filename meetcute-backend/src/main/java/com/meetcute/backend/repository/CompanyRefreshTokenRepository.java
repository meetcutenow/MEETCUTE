package com.meetcute.backend.repository;

import com.meetcute.backend.entity.CompanyRefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface CompanyRefreshTokenRepository extends JpaRepository<CompanyRefreshToken, Long> {

    Optional<CompanyRefreshToken> findByTokenHash(String tokenHash);

    @Modifying
    @Transactional
    @Query("UPDATE CompanyRefreshToken t SET t.isRevoked = true WHERE t.company.id = :cid")
    void revokeAllByCompanyId(@Param("cid") String companyId);

    @Modifying
    @Transactional
    void deleteByExpiresAtBeforeOrIsRevokedTrue(LocalDateTime expires);
}