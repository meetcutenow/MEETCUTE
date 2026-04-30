package com.meetcute.backend.repository;

import com.meetcute.backend.entity.Like;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LikeRepository extends JpaRepository<Like, Long> {

    boolean existsByLikerIdAndLikedId(String likerId, String likedId);
}