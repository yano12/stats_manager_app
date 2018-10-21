class Team < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  has_many :following, through: :active_relationships,  source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }
  
  # 渡された文字列のハッシュ値を返す
  def Team.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
  
  # チームを検索する
  def self.search(search)
    if search
      where(['name LIKE ?', "%#{search}%"])
    else
      Team.all
    end
  end
  
  # ユーザーをフォローする
  def follow(other_team)
    following << other_team
  end

  # ユーザーをフォロー解除する
  def unfollow(other_team)
    active_relationships.find_by(followed_id: other_team.id).destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す
  def following?(other_team)
    following.include?(other_team)
  end
  
  def players_names
    team = Team.find(params[:id])
    @players = team.players
  end
  
  # フォローしたチームに所属しているプレイヤーの投稿を返す
  def feed
    following_ids = "SELECT followed_id FROM relationships
                     WHERE follower_id = :team_id"
    #following_team_players_name = "SELECT name FROM players
     #                              WHERE team_id IN following_ids"
    Micropost.including_replies(id)
    .where("team_id IN (#{following_ids}) OR team_id = :team_id", team_id: id)
  end
end